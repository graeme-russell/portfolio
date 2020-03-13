%% Dual Webcam Recording Script:
clear all
close all
%% Set up Connection to Webcam
% This  uses the "Logitech HD Webcam C270" camera.

camlist = webcamlist;
cam1 = webcam(1); cam2 = webcam(2);

%% Preview Video Stream
% To open a Video Preview window, use the |preview| function. The Video
% preview window displays the live video stream from the device.

preview(cam1); preview(cam2);

%% Record Video
% Edit filenames here.
vid1 = VideoWriter('C3.avi'); open(vid1);
vid2 = VideoWriter('C4.avi'); open(vid2);
k = 1;
% Pause script until user is ready to record. Could use framerate
% information to ask user how long they want to record for. Could adapt
% code to use streamed pixels.
y = input('Record?');
while k < 300 % Record for 3 seconds
    A1 = snapshot(cam1);    writeVideo(vid1,A1)
    A2 = snapshot(cam2);    writeVideo(vid2,A2)
    k = k+1;
end
close(vid1);close(vid2)

%% Start Analysis:
filename_C1 = 'C3.avi';
filename_C2 = 'C4.avi';

%% Create System Objects
% Create System objects used for reading the video frames, detecting
% foreground objects, and displaying results.

% Initialize Video I/O Create objects for reading a video from a file,
% drawing the tracked objects in each frame, and playing the video.

% Create a video file reader.
C1.reader = vision.VideoFileReader(filename_C1);
C2.reader = vision.VideoFileReader(filename_C2);

% Create two video players, one to display the video, and one to display
% the foreground mask.
C1.maskPlayer = vision.VideoPlayer('Position', [740, 400, 900, 600]);
C1.videoPlayer = vision.VideoPlayer('Position', [20, 400, 900, 600]);
C2.maskPlayer = vision.VideoPlayer('Position', [740, 20, 900, 600]);
C2.videoPlayer = vision.VideoPlayer('Position', [20, 20, 900, 600]);

% These properties are important for optimising the algorithm based on your
% use case.
C1.detector = vision.ForegroundDetector('NumTrainingFrames', 5);
C2.detector = vision.ForegroundDetector('NumTrainingFrames', 5);

% NumGaussians can be set a number of either 3, 4, or (defualt) 5 typically
% Changing it didn't seem to do much to the image

% NumTrainingFrames models how many frames it should use to model the
% background Increasing this value makes the background more visible 4/5
% seems optimal before we start getting more and more background in the
% image. This is because the algorithim happens to be trained before the
% object is on scene. This also eliminates sensitivity to things like
% creasing paper.

% LearningRate is how quickly the model adapts to the changing image, for
% example when set to a high number (clsoe to 1) the model highlights the
% changing position of the ball however only as a half-moon (as the ball is
% the same colour). This may be necessary for high speed events but makes a
% very noisy image as deviations in lighting begin to show. The defualt
% 0.005 is adequate.

% 'MinimumBackgroundRatio', (default) 0.7 doesn't change the image much.

% Connected groups of foreground pixels are likely to correspond to moving
% objects.  The blob analysis System object is used to find such groups
% (called 'blobs' or 'connected components'), and compute their
% characteristics, such as area, centroid, and the bounding box.

% A avenue to explore is using area information to associate the same
% object from different angles of view (spherical ball will have constant
% area as function of distance). 

% This technique assumes reasonable detection of only the one object of
% interest and uses the centroid of the blob as the center of the object.

% These properties are important for optimising the algorithm based on your
% use case. Here I added the property MaximumCount-1 to simplify. For speed
% BoundingBoxOutputPort and AreaOutputPort have been set to false. If the
% blob is on the border we do not know how much of object is in the field
% of view and thus the centroid may be highly inacurate thus the blob is
% ignored.

C1.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', false, ...
    'AreaOutputPort', false, 'CentroidOutputPort', true, ...
    'MinimumBlobArea', 400, 'MaximumCount', 1, ...
    'ExcludeBorderBlobs', true);
C2.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', false, ...
    'AreaOutputPort', false, 'CentroidOutputPort', true, ...
    'MinimumBlobArea', 400, 'MaximumCount', 1, ...
    'ExcludeBorderBlobs', true);

%% Camera Details

% Image size - assuming same resolution for both feeds
hor_pix = size(C1.reader.step(),2);
ver_pix = size(C1.reader.step(),1);

% Values Which Are Inherent to the Camera used - found using calibration
% script (preliminaries). Logitech C270 documented FOV is 60 degrees using
% the aspect ration this gives a vertical angle of view of 45. This agrees
% with our calibration test.
hor_FOV_angle = 60; % horizontal angle of view
ver_FOV_angle = (ver_pix/hor_pix)*hor_FOV_angle; % vertical angle of view

% Relative camera geometry - change depending on setup.
x0 = 197+60;   % Horizontal distance between cameras as viewed from camera 1
y0 = 162+63;   % Vertical distance between cameras as viewed from camera 1

% Even image sizes means never being in the center
origin_x = hor_pix/2 ;
origin_y = ver_pix/2 ;

h_pix_ang = hor_FOV_angle/hor_pix; % degrees per pixel across
v_pix_ang = ver_FOV_angle/ver_pix; % degrees per pixel up

theta_x = atand(y0/x0) ;
theta_y = atand(x0/y0) ;
L0 = sqrt(x0^2+y0^2) ; % Distance between cameras

k = 1; % Save data

%% Loop for every frame - Get centroid Data
while ~isDone(C1.reader)
    frame_C1 = C1.reader.step();
    frame_C2 = C2.reader.step();
    
    % Detect foreground.
    mask_C1 = C1.detector.step(frame_C1);
    mask_C2 = C2.detector.step(frame_C2);
    
    % Apply morphological operations to remove noise and fill in holes.
    % Change the strel functions to optimise based on the object you want
    % to track.
    
    % strel(nhood) creates a structuring element, where NHOOD is a matrix
    % of 1s and 0s that specifies the neighborhood. This might be able to
    % help define the shape of the object you are trying to track. Create a
    % elipse for rubgy etc. this has limitations as at different angles
    % non-symetric objects have a different shape. I think it is
    % unavoidable to have to change this parameter for different
    % sports/objects. I think this is fair and probably how Hawkeye does
    % it. Every camera could even use different post processing.
    
    mask_C1 = imopen(mask_C1, strel('disk',5));
    mask_C2 = imopen(mask_C2, strel('disk',5));
    % imopen effectively ignores any foreground detections smaller than the
    % structuring element.
    mask_C1 = imclose(mask_C1, strel('disk', 10));
    mask_C2 = imclose(mask_C2, strel('disk', 10));
    % imclose to connect detected foreground, using a circular structuring
    % element in both cases as we will primarily be looking at circular
    % objects. In general this should be small as there shouldn't be large
    % occlusions. If there are you could increase this to potentially
    % "connect the dots".
    mask_C1 = imfill(mask_C1, 'holes');
    mask_C2 = imfill(mask_C2, 'holes');
    % The foreground detector does well not not have noise within a
    % detected change. But in case there is, we are covered.
    
    % Perform blob analysis to find connected components.
    centroids_C1 = C1.blobAnalyser.step(mask_C1);
    centroids_C2 = C2.blobAnalyser.step(mask_C2);
    
    % Play videos
    C1.maskPlayer.step(mask_C1);
    C1.videoPlayer.step(frame_C1);
    C2.maskPlayer.step(mask_C2);
    C2.videoPlayer.step(frame_C2);
    
    % Don't do anything if nothing has been found (in either view).
    if ~isempty(centroids_C1) && ~isempty(centroids_C2)
        
        C1_ball_x(k) = centroids_C1(1);
        C1_ball_y(k) = centroids_C1(2);
        C2_ball_x(k) = centroids_C2(1);
        C2_ball_y(k) = centroids_C2(2);
        
        k = k + 1;
    end
    
    % Can copy analysis here for procedural information
    
end
%% Analysis
% Angles relative to the Origin for Camera 1

h_angle = (C1_ball_x - origin_x)*h_pix_ang; % horizontal angle
% Matlab defines image origin as top left so a negative is needed here:
v_angle = -(C1_ball_y-origin_y)*v_pix_ang; % vertical angle

alpha = h_angle ;

gamma1 = v_angle ;

% Angles relative to the Origin for Camera 2

h_angle = (C2_ball_x - origin_x)*h_pix_ang; % horizontal angle
v_angle = -(C2_ball_y-origin_y)*v_pix_ang; % vertical angle

beta =  -h_angle ; % Due to our definitions we use a negative here

gamma2 = v_angle ;

% Triangulation
p = 90 - theta_y + beta ;
q = 90 - theta_x + alpha ;
d = L0.*(sind(p).*sind(q))./(sind(p+q));
L1 = d./sind(q) ;
L2 = d./sind(p) ;

x = L1.*sind(alpha);
y = L2.*sind(beta) ;
z1 = sqrt(x.^2 + (y+y0).^2).*tand(gamma1)+15; 
z2 = sqrt((x+x0).^2 + y.^2).*tand(gamma2)+15;
z = mean([z1;z2]);
% Show 3D position of tracked object. Could improve with
% interpolation when not known? Data can be saved to use for further
% analysis like mechanics.
hold on
scatter3(x,y,z)
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis('square')

%% Clean up
% Once the connection is no longer needed, clear the associated webcam
% variable.
clear cam1
clear cam2
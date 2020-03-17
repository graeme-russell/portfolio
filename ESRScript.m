%% Polarisation Calculation Script
% Joseph Plummer and Graeme Russell. 
% 5/10/18
%   Code for analysing ESR Spectra. Used to calculate polarisation of
% Caesium 133 using multiple aproximations to the area under the two
% highest resolved transitions. In signal averaged spectra corresponding to
% the row number in 'data_directories.txt' inputted into array N.
%   Note: files 'data_directories.txt', and 'bf.m' ust be inserted into the
% same folder as this script!
 
clc; clear all
 
% Import list of files
dir = importdata('data_directories.txt');
 
% Input which files to analyse
N = [43:49]; 
 
% Input voltage slightly lower than sawtooth function
V = 1.48;    % Rubidium
%V = 1.945;   % Caesium
 
% Initiate data processing, repeat for each selected data set
for n = N
    
    % Import data and seperate into various components 
    A = importdata(dir{n}); 
    
    timestamp = A(:,1);     % time
    x = A(:,2);             % in-phase demodulated signal
    y = A(:,3);             % quadrature demodulated signal
    saw = A(:,6);           % B0 coil voltage
    % Note: reverse x and y to easily examine in-phase/quadrature data
    
    % Automatically detect a peak every 3e3 units (~20s) above V
    [~, LOCS] = findpeaks(saw,'MinPeakDistance',3e3,'MinPeakHeight',V);
    
    % Use the location of the peaks to determine the average seperation
    % between them i.e. automatically find the period of the sawtooth
    % function
    for i=1:length(LOCS)-1
        L(i)=(LOCS(i+1)-LOCS(i));
    end
    
    % Approximate the location of the start of each sweep
    LOCS = ([0:length(L)].*round(mean(L)))+min(LOCS);
    
    % Seperate demodulated signal into a single sweep
    for i=1:length(LOCS)-1
        ESR(i,:) = x(LOCS(i):LOCS(i+1));
    end
    
    % Perform signal average
    X{n} = trimmean(ESR,1)';
    X{n} = bf(X{n},'linear');
    % Find standard deviation associate with each point of signal average
    error = std(ESR);
    
    % Find two highest peaks in signal average
    [H, LOC, W, P] = findpeaks(abs(X{n}),'SortStr','descend','NPeaks',2);
    
    % Calculate Polarisation + Errors for different approximations of r
    % where error is calculated using error propagation
    for i = 1:3
        % Loop is of the form:
        
        % Define A, area approximation
        % Calculate error of A
        
        % Calculate r
        % Calculate Polarisation
        
        if i == 1       % Height
            
            A = H;
            AErr = error(LOC)/sqrt(length(ESR)-1);
            
            r = A(1)/A(2);
            Po(i,n) = (7*r-4)/(7*r+4); % Baranga (1998)    
            
        elseif i == 2   % Prominence Area
            
            A = W.*P;
            AErr = sqrt(2)*W.*error(LOC)/sqrt(length(ESR)-1);
            
            r = A(1)/A(2);
            Po(i,n) = (7*r-4)/(7*r+4);
            
        else            % Height Area
            
            A = W.*H;
            AErr = W.*error(LOC)/sqrt(length(ESR)-1);
            
            r = A(1)/A(2);
            Po(i,n) = (7*r-4)/(7*r+4);
            
        end
        
        % Calculate error of r
        rERR = sqrt( (A(2)^-2)*AErr(1)^2 + (A(1)*(A(2)^-2))*AErr(2)^2 );
        
        % Calculate error of polarisation
        pERR(i,n) = rERR * ( (7/(7*r+4)) - (7*(7*r-4)/(7*r+4)^2) );
        
        % Output Polarisation and its corresponding error as a percentage
        [num2str(100*Po(i,n)),' ',num2str(100*pERR(i,n))]
    end
 
    clearvars -except dir N V Po pERR X
    
end

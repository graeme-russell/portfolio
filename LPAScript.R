###########################################################################
#### Modification, adaptation, or use of any portion of this code for  ####
#### any purpose must include a reference to the full manuscript       ####
#### citation provided below. This code is provided 'as is.' The       ####
#### authors are under no obligation to provide assistance or          ####
#### instruction pertaining to the use or operation of this code.      ####
####                                                                   ####
#### To cite this model use:                                           ####
#### citation redacted for blind review                                ####
###########################################################################
#library(lme4) # load package for RCM analysis

#####################################################
######## Data Generation Simulation #################
#####################################################
n <- 150 # number of people per relationship
t <- 100 # number of time points per person
eff <- .7 # effect size of relationship (r^2)

person <- rep(1:n,each=t) # create person identifier
time <- rep(1:t,n) # create time identifier

### x -> y Data ###
dat <- sapply(1:n, function(i) {
	x <- array(0,dim=c(t,1)) # array to hold "self-efficacy" data
	y <- array(0,dim=c(t,1)) # array to hold "performance" data
	y[1,] <- rnorm(1,0,1) # choose random starting value for each individuals "self-efficacy"
	x[1,] <- rnorm(1,0,1) # choose random starting value for each individuals "performance"
	for(j in 2:t) { # function to link self-efficacy and performance over time
		x[j,1] <- rnorm(1,0,1)
		y[j,1] <- eff*x[(j-1),1] + (1-eff)*rnorm(1,0,1)		
	}
	lagx <- c(NA,x[1:(t-1),1]) # create lagged version of "self-efficacy"
	lagy <- c(NA,y[1:(t-1),1]) # create lagged version of "performance"
	dat <- data.frame(x,y,lagx,lagy) # compile all relevant variables per person
return(dat)},simplify=F)
dat <- do.call(rbind,dat) # combine all individuals data

cond <- rep(1,n*t) # variable to represent the se -> perf relationship
dat1 <- data.frame(cond,person,time,dat) # add in variables representing person, time, and condition to relevant x and y variables

### y -> x Data ###
dat <- sapply(1:n, function(i) {
	x <- array(0,dim=c(t,1))
	y <- array(0,dim=c(t,1))
	y[1,] <- rnorm(1,0,1)
	x[1,] <- rnorm(1,0,1)
	for(j in 2:t) {
		x[j,1] <- eff*y[(j-1),1] + (1-eff)*rnorm(1,0,1)		
		y[j,1] <- rnorm(1,0,1)
	}
	lagx <- c(NA,x[1:(t-1),1])
	lagy <- c(NA,y[1:(t-1),1])
	dat <- data.frame(x,y,lagx,lagy)
return(dat)},simplify=F)
dat <- do.call(rbind,dat)

cond <- rep(2,n*t) # variable to represent the perf -> se relationship
person <- person+n # variable to increment the person identifier
dat2 <- data.frame(cond,person,time,dat)

### x <-> y Data ###
dat <- sapply(1:n, function(i) {
	x <- array(0,dim=c(t,1))
	y <- array(0,dim=c(t,1))
	y[1,] <- rnorm(1,0,1)
	x[1,] <- rnorm(1,0,1)
	for(j in 2:t) {
		x[j,1] <- eff*y[(j-1),1] + (1-eff)*rnorm(1,0,1)
		y[j,1] <- eff*x[(j-1),1] + (1-eff)*rnorm(1,0,1)		
	}
	lagx <- c(NA,x[1:(t-1),1])
	lagy <- c(NA,y[1:(t-1),1])
	dat <- data.frame(x,y,lagx,lagy)
return(dat)},simplify=F)
dat <- do.call(rbind,dat)

cond <- rep(3,n*t) # variable to represent the se <-> perf relationship
person <- person+n
dat3 <- data.frame(cond,person,time,dat)

### Aggregate Data ###
dat4 <- rbind(dat1,dat2,dat3) # combine data from all three conditions into aggregate data set


###############################################################
############ Nomothetic Statistical Analysis ##################
###############################################################
## Multiple Regression Models for x -> y Data ##
fm1 <- lm(y ~ 1 + time + lagx, data = dat1) # model regressing perf on se
summary(fm1)
fm2 <- lm(x ~ 1 + time + lagy, data = dat1) # model regressing se on perf
summary(fm2)

## Multiple Regression Models for y -> x Data ##
fm3 <- lm(y ~ 1 + time + lagx, data = dat2) # model regressing perf on se
summary(fm3)
fm4 <- lm(x ~ 1 + time + lagy, data = dat2) # model regressing se on perf
summary(fm4)

## Multiple Regression Models for x <-> y Data ##
fm5 <- lm(y ~ 1 + time + lagx, data = dat3) # model regressing perf on se
summary(fm5)
fm6 <- lm(x ~ 1 + time + lagy, data = dat3) # model regressing se on perf
summary(fm6)

## Multiple Regression Models for Combined Data ##
fm7 <- lm(y ~ 1 + time + lagx, data = dat4) # model regressing perf on se
summary(fm7)
fm8 <- lm(x ~ 1 + time + lagy, data = dat4) # model regressing se on perf
summary(fm8)

## Random Coefficient Models for Combined Data ##
fm10 <- lmer(y ~ 1 + (1|person), data=dat4)
summary(fm10)
fm11 <- lmer(x ~ 1 + (1|person), data=dat4)
summary(fm11)
fm12 <- lmer(y ~ 1 + time + (1 + time|person), data=dat4)
summary(fm12)
fm13 <- lmer(x ~ 1 + time + (1 + time|person), data=dat4)
summary(fm13)
fm14 <- lmer(y ~ 1 + time + lagx + (1|person), data=dat4)
summary(fm14)
fm15 <- lmer(x ~ 1 + time + lagy + (1|person), data=dat4)
summary(fm15)
fm16 <- lmer(y ~ 1 + time + lagx + (1|person) + (0 + lagx|person), data=dat4) 
summary(fm16)
anova(fm14,fm16)
fm17 <- lmer(x ~ 1 + time + lagy + (1|person) + (0 + lagy|person), data=dat4) 
summary(fm17)
anova(fm15,fm17)

###############################################################
############ Idiographic Statistical Analysis #################
###############################################################
rels <- t(sapply(unique(dat4$person), function(x) {
	temp <- dat4[dat4$person==x,]
	lagx_y <- cor(temp$lagx,temp$y,use="complete.obs")
	lagy_x <- cor(temp$lagy,temp$x,use="complete.obs")
	fm1 <- lm(y ~ 1 + time + lagx, data = temp) # model regressing perf on se
	beta_lagx <- summary(fm1)$coefficient[3,1]
	fm2 <- lm(x ~ 1 + time + lagy, data = temp) # model regressing se on perf
	beta_lagy <- summary(fm2)$coefficient[3,1]
	return(c(lagx_y,lagy_x,beta_lagx,beta_lagy))
}))

rels <- data.frame(rep(1:450),rels)
names(rels) <- c("person","cor_lagx_y","cor_lagy_x","beta_lagx","beta_lagy")

##################################
############ LPA #################
##################################

library(tidyLPA)
library(dplyr)

N <- 5
LMRT <- tibble(.rows = 4)

profiles <- rels[] %>%
  select(cor_lagx_y, cor_lagy_x) %>%
  single_imputation() %>%
  estimate_profiles(1:N)


fit <- get_fit(profiles) %>% 
  select(c(LogLik,AIC,BIC,SABIC,BLRT_val,BLRT_p,Entropy))

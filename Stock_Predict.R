
### Library
library(forecast)
library(timetk)
library(sweep)
library(forecast)
library(tidyquant)
library(tidyverse)
library(LINselect)
library(tsoutliers)
library(expsmooth)
library(fma)
library(vars)

### Enter Training History (Years) and Forecast Horizon (Days)

Years_Forecast_History<-13
L <-3 #short term forecast horizon
tingo_key<- #Self Provided

################################################################  NNETAR Parameters  ##############################################

RPT <-2000 #Repeats
decay_N<-.005  #Low Decay
S_N<-10
PATHS<-200

########################################## High and Low Reserve & Long Term  ####################################
length_analysis_short_term <-Years_Forecast_History * 252


get_high_R<-function(g) {
  g <-as.xts(g)
  LE <-nrow(g)
  SE <-LE- length_analysis_short_term
  g <-as.numeric(g[SE:LE,2])
  g<- na.fill(g, fill = 0)
  g[is.nan(g)] <- 0
  return(g) 
}


get_low_R<-function(g) {
  g <-as.xts(g)
  LE <-nrow(g)
  SE <-LE- length_analysis_short_term
  g <-as.numeric(g[SE:LE,3])
  g<- na.fill(g, fill = 0)
  g[is.nan(g)] <- 0
  return(g) 
}



### CIK
getSymbols("BA", src="tiingo", api.key=tingo_key)

HIGH     <-get_high_R(BA)
LOW     <-get_low_R(BA)

###NNETAR_High
TFIT <-tbats(HIGH)
FIT <-fitted(TFIT, type="regression")
FCAST <-forecast(TFIT, h=L)
FCAST <-data.frame(FCAST)
CVA_ARF_H <-as.numeric(FCAST[,1])

FIT <- nnetar(HIGH, size=S_N, repeats = RPT, xreg = FIT, decay = decay_N)
sweep::sw_glance(FIT)
SD<- sd(FIT$residuals, na.rm=TRUE)
MEAN<- mean(FIT$residuals, na.rm=TRUE)
#myinnovs <- rnorm(STFH*PATHS, mean= 0, sd=SD)
myinnovs <- rpois(L*PATHS, .96)
FCAST<- forecast(FIT, h=L ,PI=TRUE, xreg = CVA_ARF_H, npaths=PATHS, innov=myinnovs)


acc<-accuracy(FIT)
MAPE_High <-acc[5]  #MAPE
fcast_NNETAR_high <-data.frame(FCAST)



###NNETAR_LOW
TFIT <-tbats(LOW)
FIT <-fitted(TFIT, type="regression")
FCAST <-forecast(TFIT, h=L)
FCAST <-data.frame(FCAST)
CVA_ARF_L <-as.numeric(FCAST[,1])

FIT<- nnetar(LOW, size=S_N, repeats = RPT, xreg = FIT, decay = decay_N)
sweep::sw_glance(FIT)
SD <- sd(FIT$residuals, na.rm=TRUE)
MEAN <- mean(FIT$residuals, na.rm=TRUE)
#myinnovs <- rnorm(STFH*PATHS, mean= 0, sd=SD)
myinnovs <- rpois(L*PATHS, .96)
FCAST<- forecast(FIT, h=L, PI=TRUE, xreg = CVA_ARF_L, npaths=PATHS, innov=myinnovs)

acc<-accuracy(FIT)
MAPE_LOW <-acc[5]  #MAPE

fcast_NNETAR_low <-data.frame(FCAST)

### Results
accuracy_results <-data.frame(MAPE_LOW, MAPE_High)/100
colnames(accuracy_results)<-c("MAPE_Low", "MAPE_High")
accuracy_results$Error_Low<-accuracy_results$MAPE_Low * mean(fcast_NNETAR_low$Point.Forecast)
accuracy_results$Error_High <-accuracy_results$MAPE_High * mean(fcast_NNETAR_high$Point.Forecast)
accuracy_results
fcast_NNETAR_low
fcast_NNETAR_high

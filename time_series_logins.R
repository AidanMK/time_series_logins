#############################################
#
#   Visualization and time series 
#     modeling of app login data 
#
#############################################


require(jsonlite)   #To read json file
library(lubridate)  #To get time formats
library(data.table) #To collapse data and get counts
library(pracma)     #To get floor function
library(reshape2)   #To reshape for plots
library(ggplot2)    #To make plots
library(scales)     #To format time axis of plots
library(tseries)     
library(forecast)   


#Input working directory
mydir <- "C:\\Users"

setwd(mydir)

#Clear objects
rm(list=ls(pattern="*"))

#Number display
options(scipen=999)

#Set local time zone
mytimezone <- "America/Los_Angeles"
Sys.setenv(TZ=mytimezone)

#Set interval to collapse data
minuteinterval <- 15


#########################
# Define functions
#########################

#Define function read_data_json
#Reads in the data from json, formats times, and inputs to data frame
#Note: the dataset is a list of timestamps corresponding to app logins
 #Args:      jsondata (.json file)
 #Returns:   Data frame   

read_data_json <- function(jsondata) {

  data_read <- do.call(rbind,lapply(paste(readLines(jsondata, warn=FALSE),
                                          collapse=""), 
                               jsonlite::fromJSON))
  data <- unlist(data_read)
  times <- as.POSIXct(data,format="%Y-%m-%d %H:%M:%S")
  data_df <- as.data.frame(times) 
  colnames(data_df) <- c("timestamp")
  return(data_df)    
}    

#Define function collapse_data_df
#Collapses the data to X-minute intervals
#Args:      data_df (dataframe with login timestamps)
#           interval (integer, must divide evenly into 60)
#Returns:   Data frame   

do_collapse_data <- function(data_df,interval) {
  
  data_df$minutegroup <- floor(minute(data_df$timestamp)/interval)*interval
  data_df$collapsedate <- (data_df$timestamp - 
                           minute(data_df$timestamp)*60 +
                           data_df$minutegroup*60 - 
                           second(data_df$timestamp))     
  data_dtable <- data.table(data_df)
  collapse_data <- data_dtable[, .N, by = .(collapsedate)]
  colnames(collapse_data) <- c("collapsedate","number_logins")
  return(collapse_data)    
}

#Define function fill_time_series
#Fills in gaps in the time series
#Args:      collapse_data (dataframe with logins per interval)
#           interval (integer, must divide evenly into 60)
#Returns:   Data frame   

fill_time_series <- function(collapse_data, interval) {
  
 #Sort data, find first and last time  
  sorted_df <- collapse_data[order(collapse_data$collapsedate),]
  last_index <- length(sorted_df$collapsedate)  
  min <- sorted_df$collapsedate[1]
  max <- sorted_df$collapsedate[last_index] 
  
 #Create list of full time series and convert to data frame
  bystring <- paste(interval,"mins",sep=" ")
  full_times_df <- data.frame(list(fulltime=seq(min, max, by=bystring)))
  
 #Merge full time series to login data 
  collapse_data_full <- merge(collapse_data, full_times_df, 
                        by.x="collapsedate", by.y="fulltime",  all=T)

 #Replace number of logins =0 if number of logins =NA
  collapse_data_full$number_logins[
    which(is.na(collapse_data_full$number_logins))] <- 0 
  return(collapse_data_full)      
}
  
#Define function frequency_plot
#Plot frequency of number of logins
#Args:      collapse_data (dataframe collapsed to intervals)
#Returns:   frequencyplot.pdf   

frequency_plot <- function(collapse_data) {

  ggplot(collapse_data, aes(x=number_logins)) + 
    geom_bar(color="gray16", fill="white") +
    xlab("Number of logins")         
  ggsave("frequencyplot.pdf", height = 5, width = 6)      
}

#Define function one_month_time_plot
#Plot number of logins in a single month
#Args:      collapse_data (dataframe collapsed to intervals)
#           mon (month - integer between 1 and 12)
#Returns:   onemonthtimeplot.pdf   

one_month_time_plot <- function(collapse_data,mon) {

  one_month_data <- collapse_data[month(collapse_data$collapsedate)==mon]
  one_month_data$ma_logins = ma(one_month_data$number_logins, order=12)
  ymax <- ceil(max(one_month_data$number_logins))   
  ggplot() +
    geom_line(data = one_month_data, 
              aes(x = collapsedate, 
                  y = number_logins, color = "Number of logins")) +
    geom_line(data = one_month_data, 
              aes(x = collapsedate, 
                  y = ma_logins, color = "Moving average")) +
    ylab("Number of logins") +
    xlab("Date")     
        
  ggsave("onemonthtimeplot.pdf", height = 2, width = 10)    
}

#Define function within_day_plot
#Plot average and median logins by time of day
#Args:      collapse_data (dataframe collapsed to intervals)
#Returns:   withindayplot.pdf   

within_day_plot <- function(collapse_data) {
  
  #Collapse to day level 
  data_dtable <- data.table(collapse_data)
  data_dtable$time <- format(data_dtable$collapsedate, "%H:%M")
  data_timeofday <- data_dtable[, .(mean_logins=mean(number_logins), 
                                    median_logins=quantile(number_logins,probs=.50)), 
                                by = .(time)]

  #Format time
  data_timeofday <- data_timeofday[order(time),]
  data_timeofday$timeformat <- as.POSIXct(strptime(data_timeofday$time, 
                                                   format="%H:%M",
                                                   tz = mytimezone))
  
  #Make plot with mean and median    
  reshape_df <- melt(data_timeofday, id.vars = c('timeformat'), 
                     measure.vars=c('mean_logins','median_logins'))
  ymax <- ceil(max(reshape_df$value))      
  ggplot(reshape_df, aes(x = timeformat, y = value)) + 
    geom_line(aes(color = variable, alpha = variable), size = 1) +
    scale_color_manual(values = c("deepskyblue3", "gray40")) +
    scale_alpha_manual(values=c(1,0.55)) +    
    scale_x_datetime(name="Time of day", 
                     date_breaks("1 hour"), 
                     labels = date_format("%H:%M",tz = mytimezone)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0,ymax)) +    
    ylab("Number of logins") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
  ggsave("withindayplot.pdf", height = 5, width = 8)    
}

#Define function within_day_byweekday_plot
#Plot average and median logins by time of day and 
# day of week
#Args:      collapse_data (dataframe collapsed to intervals)
#Returns:   dayofweekplot.pdf   

within_day_byweekday_plot <- function(collapse_data) {
  
  #Collapse to time of day by day of week
  data_dtable <- data.table(collapse_data)
  data_dtable$time <- format(data_dtable$collapsedate, "%H:%M")
  data_dtable$weekday <- format(data_dtable$collapsedate, "%a")    
  data_timeofday <- data_dtable[, .(mean_logins=mean(number_logins)), 
                                    by = .(time,weekday)]
  
  #Format time
  data_timeofday <- data_timeofday[order(time),]
  data_timeofday$timeformat <- as.POSIXct(strptime(data_timeofday$time, 
                                                   format="%H:%M",
                                                   tz = mytimezone))

  #Reshape data and sort
  reshape_df <- melt(data_timeofday, id.vars = c('weekday','timeformat'), 
                     measure.vars=c('mean_logins'))
  reshape_df <- reshape_df[order(weekday,timeformat),]

  #Order labels   
  dayofweekorder <- c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")
  i = 0
  for (day in dayofweekorder) {
    i = i + 1
    newlabel = paste(i, ".", day, sep="")
    reshape_df$weekday[reshape_df$weekday == day] <- newlabel
  }
  
  #Create plot
  ymax <- ceil(max(reshape_df$value))    
  colorlist <- c(
    "blue","red","green3","orange",
    "purple","black","turquoise3"
  )  
  ggplot(reshape_df, aes(x = timeformat, y = value, 
                         group=weekday, color=weekday)) + 
    geom_line() +
    scale_color_manual(values = colorlist) +
    scale_alpha_manual(values=c(1,1,1,1,1,1,1)) +    
    scale_x_datetime(name="Time of day", 
                     date_breaks("3 hours"), 
                     labels = date_format("%H:%M",tz = mytimezone)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0,ymax)) +    
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    facet_wrap(~weekday,nrow=1) +
    ylab("Average number of logins") +    
    theme(legend.position="none")
  ggsave("dayofweekplot.pdf", height = 2, width = 10)  
}

#Define function within_day_bymonth_plot
#Plot average and median logins by time of day and 
# month
#Args:      collapse_data (dataframe collapsed to intervals)
#Returns:   monthplot.pdf   

within_day_bymonth_plot <- function(collapse_data) {
  
  #Collapse to month by time of day
  data_dtable <- data.table(collapse_data)
  data_dtable$time <- format(data_dtable$collapsedate, "%H:%M")
  data_dtable$month <- format(data_dtable$collapsedate, "%m")    
  data_timeofday <- data_dtable[, .(mean_logins=mean(number_logins)), 
                                by = .(time,month)]
  
  #Format time
  data_timeofday <- data_timeofday[order(time),]
  data_timeofday$timeformat <- as.POSIXct(strptime(data_timeofday$time, 
                                                   format="%H:%M",
                                                   tz = mytimezone))
  
  #Reshape data and sort
  reshape_df <- melt(data_timeofday, id.vars = c('month','timeformat'), 
                     measure.vars=c('mean_logins'))
  reshape_df <- reshape_df[order(month,timeformat),]
  
  #Create plot
  ymax <- ceil(max(reshape_df$value))    
  colorlist <- c(
    "mediumorchid1","mediumorchid2","mediumorchid3","mediumorchid4",
    "royalblue4","royalblue3","royalblue2","royalblue1"    
  )
  ggplot(reshape_df, aes(x = timeformat, y = value, 
                         group=month, color=month)) + 
    geom_line() +
    scale_color_manual(values = colorlist) +
    scale_alpha_manual(values=c(1,1,1,1,1,1,1)) +    
    scale_x_datetime(name="Time of day", 
                     date_breaks("3 hours"), 
                     labels = date_format("%H:%M",tz = mytimezone)) +
    scale_y_continuous(expand = c(0, 0), limits = c(0,ymax)) +    
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    facet_wrap(~month,nrow=4) +
    ylab("Average number of logins") +    
    theme(legend.position="none")
  ggsave("monthplot.pdf", height = 8, width = 5)  
}

#Define function do_forecast
#Prepares data, fits models, returns forecasts
#Args:      collapse_data (dataframe collapsed to intervals)
#Returns:   Forecast plots tbatsplot.pdf and stlmplot.pdf   

do_forecast <- function(collapse_data) {
  
  #Clean data - replace outliers
  collapse_data$number_logins_clean <- 
     tsclean(collapse_data$number_logins)
  cleaned = collapse_data[collapse_data$number_logins != 
                          collapse_data$number_logins_clean]
  print(cleaned)
  
  #Check stationarity: Augmented Dickey-Fuller test
  print(adf.test(collapse_data$number_logins_clean))
  
  #Define training and test data
  train_data <-collapse_data[month(collapse_data$collapsedate)<7]
  test_data <-collapse_data[month(collapse_data$collapsedate)>=7]
  
  #Adjust for multiple seasonality
  #Two levels: Day-level and week-level
  train_msts <- msts(train_data$number_logins_clean, 
                     seasonal.periods = 
                       c(24*(60/minuteinterval),
                         24*(60/minuteinterval)*7))
  
  #Fit models
  fit_tbats <- tbats(train_msts)
  components <- tbats.components(fit_tbats)
  plot(components)
  checkresiduals(fit_tbats)
  fcast <- forecast(fit_tbats, h=length(test_data$number_logins_clean))
  pdf("tbatsplot.pdf") 
  plot(fcast)
  dev.off()
  print(accuracy(fcast$mean,test_data$number_logins_clean))
  
  fit_stlm <- stlm(train_msts,s.window="periodic")
  checkresiduals(fit_stlm)  
  fcast <- forecast(fit_stlm, h=length(test_data$number_logins_clean))
  pdf("stlmplot.pdf")     
  plot(fcast)   
  dev.off()
  print(accuracy(fcast$mean,test_data$number_logins_clean))    
}


#########################
# Execute functions
#########################

data_df <- read_data_json("Econ_Exercise.json")

collapse_data_partial <- do_collapse_data(data_df,
                                          minuteinterval)

collapse_data_full <- fill_time_series(collapse_data_partial,
                                       minuteinterval)

frequency_plot(collapse_data_full)

one_month_time_plot(collapse_data_full,1)

within_day_plot(collapse_data_full)

within_day_byweekday_plot(collapse_data_full)

within_day_bymonth_plot(collapse_data_full)

do_forecast(collapse_data_full)




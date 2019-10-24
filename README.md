# time_series_logins

Program in R to visualize app logins and forecast future logins.  

**Objective:** Forecast future app logins

**Data description:** JSON dataset with timestamps  

**Exploratory data analysis:** 

The histogram below shows the distribution of number of logins in the data, collapsed to 15-minute intervals. The distribution has a long right tail consistent with a Poisson distribution, which is what we would expect from count data. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/frequencyplot.png" width="600" height="450">

The time series below shows the number of logins over time in the month of January, along with the smoothed time series (a moving average using data from 3 hours before to 3 hours after). The data are highly cyclical, and most of this cyclical variation appears to be at the day level.

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/onemonthtimeplot.png" width="900" height="200">

The figure below looks more closely at within-day variation in logins. The plot shows the average and median logins per 15-minute interval over all days in the data. As we would expect, logins are lowest late at night and early in the morning. Average logins are fairly consistent from 8:00 am to 3:00 pm, increase between 5:00 pm and 7:00 pm, and fall after 7:00 pm. Although the data has a long right tail, the mean and median track each other closely, which suggests that the data is not particularly skewed. The main exception is early in the morning, when the mean is above the median; this may reflect holidays or late night-events. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/withindayplot.png" width="600" height="400">

The plots below examine how within-day variation differs by day of the week. Within-day login variation exhibits similar patterns on weekdays (Monday through Friday). The level of login volume increases during the week, reaching its highest levels on Friday evenings. Late night logins are highest on Saturdays and Sundays. Overall volume is lowest on Sundays, and unlike on other days, Sunday logins peak early in the afternoon rather than in the evening. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/dayofweekplot.png" width="950" height="200">


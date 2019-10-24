# time_series_logins

Program in R to visualize app logins and forecast future logins.  

**Objective:** Forecast future app logins.

**Data description:** JSON dataset with timestamps.

**Methods:** STLM and TBATS, two time series model that permit multiple levels of cyclicality.

**Conclusions:** The models appear to model cyclicality in the data fairly well. However, the predicted values are biased towards zero. This is likely because these models do not account for the distribution of count data, which has a long right tail.  

**Exploratory data analysis:** 

The histogram below shows the distribution of number of logins in the data, collapsed to 15-minute intervals. The distribution has a long right tail consistent with a Poisson distribution, which is what we would expect from count data. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/frequencyplot.png" width="600" height="450">

The time series below shows the number of logins over time in the month of January, along with the smoothed time series (a moving average using data from 3 hours before to 3 hours after). The data are highly cyclical, and most of this cyclical variation appears to be at the day level.

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/onemonthtimeplot.png" width="900" height="200">

The figure below looks more closely at within-day variation in logins. The plot shows the average and median logins per 15-minute interval over all days in the data. As we would expect, logins are lowest late at night and early in the morning. Average logins are fairly consistent from 8:00 am to 3:00 pm, increase between 5:00 pm and 7:00 pm, and fall after 7:00 pm. Although the data has a long right tail, the mean and median track each other closely, which suggests that the data is not particularly skewed. The main exception is early in the morning, when the mean is above the median; this may reflect holidays or late night-events. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/withindayplot.png" width="600" height="400">

The plots below examine how within-day variation differs by day of the week. Within-day login variation exhibits similar patterns on weekdays (Monday through Friday). The level of login volume increases during the week, reaching its highest levels on Friday evenings. Late night logins are highest on Saturdays and Sundays. Overall volume is lowest on Sundays, and unlike on other days, Sunday logins peak early in the afternoon rather than in the evening. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/dayofweekplot.png" width="950" height="200">

**Forecasting:** 

Before forecasting, I remove outliers from the data and split the data into training (January through June) and test (July and August) segments. The figures above show that there is cyclical variation in logins within each day, as well as across days within each week. Therefore, I use the msts() function in R to adjust for seasonal variation at both the week level and day level. I estimate two time series models that can incorporate multiple seasonality: STLM (Seasonal and Trend decomposition using Loess) and TBATS (for Trigonometric regressors, Box-Cox transformation, ARMA errors, Trend, and Seasonality). 

The figures below show the residuals and forecasts for STLM. The residual frequency plot shows that the residuals are not entirely random and mean zero. On average, the residuals are negative. There also appears to be some remaining cyclicality in the residuals, as seen in the top plot. The forecast plot shows that the predicted values pick up most of the cyclicality in the data. However, the forecasted values systematically underestimate logins. 

<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/stlmresidual.png" width="800" height="600">
<img src="https://github.com/AidanMK/time_series_logins/blob/master/plots/stlmplot.png" width="800" height="600">

Results are similar for TBATS. While TBATS is slightly more accurate - mean error (ME), root mean squared error (RMSE), and mean absolute error (MAE) are somewhat lower than for STLM - the prediction intervals are much wider.

Most of the predicted variation in these models comes through the estimated seasonal components (at the day and week level). Adding additional covariates to the model - for example, indicators for holidays and events - would likely improve the forecast accuracy. However, the distribution of the residuals suggests that the distributional assumptions of STLM and TBATS may not appropriate for modelling this data generating process. Better results might be obtained by using a time series model designed specifically for count data. 



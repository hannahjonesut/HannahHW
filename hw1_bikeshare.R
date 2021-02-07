library(tidyverse)
library(ggplot2)

bikeshare <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/bikeshare.csv')

bikes_hr = bikeshare %>%
  group_by(hr) %>%
  summarize(hourly_total = sum(total))

#ggplot(data=bikes_hr) +
 # geom_col(aes(x=hr, y=hourly_total))

ggplot(data=bikes_hr) +
  geom_line(aes(x=hr, y=hourly_total)) +
  labs(title="Bike Rentals by Hour", 
       y="Total Rentals",
       x = "Hour")

bikes_hr2 = bikeshare %>%
  group_by(hr, workingday) %>%
  summarize(hourly_total = sum(total))

#variable_names <- list(
 # "0" = "Non-working Day" ,
  #"1" = "Working Day"
#)

#variable_labeller <- function(workingday,value){
 # return(variable_names[value])
#}

ggplot(data=bikes_hr2) +
  geom_line(aes(x=hr, y=hourly_total)) +
  facet_wrap(~workingday) +
  labs(title="Bike Rentals by Hour (Non-Working Day vs Working Day)", 
       y="Total Rentals",
       x = "Hour")

eightam_tot = bikeshare %>%
  filter(hr == 8)%>%
  group_by(weathersit, workingday)%>%
  summarize(weather_tot = sum(total))

ggplot(data = eightam_tot)+
  geom_col(aes(x=weathersit, y=weather_tot))+
  facet_wrap(~workingday) +
  labs(title="Bike Rentals by Weather", 
       y="Total Rentals",
       x = "Weather Situation")

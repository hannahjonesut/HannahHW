library(tidyverse)
library(ggplot2)
library(modelr)
library(rsample)
library(mosaic)
library(parallel)
library(foreach)
library(tidyverse)
library(caret)
library(estimatr)
library(lubridate)
library(randomForest)
library(gbm)
library(pdp)


greenbuildings <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/greenbuildings.csv')

greenbuildings <- greenbuildings %>%
  mutate(yearly_rev = Rent*leasing_rate)%>%
  filter(!is.na(empl_gr))



greenbuildings_split = initial_split(greenbuildings)

# training and testing sets
n = nrow(greenbuildings)
n_train = floor(0.8*n)
n_test = n - n_train
train_cases = sample.int(n, size=n_train, replace=FALSE)
greenbuildings_train = training(greenbuildings_split)
greenbuildings_test = testing(greenbuildings_split)

forest1 = randomForest(yearly_rev ~ . - Rent - leasing_rate,
                       data=greenbuildings_train)

yhat_test = predict(forest1, greenbuildings_test)
plot(yhat_test, greenbuildings_test$yearly_rev)

modelr::rmse(forest1, greenbuildings_test)

plot(forest1)
varImpPlot(forest1)

predicted_yearly_rev_test = predict(forest1, greenbuildings_test)

greenbuildings_test$predicted_yearly_rev = predicted_yearly_rev_test

test_summ = greenbuildings_test %>%
  mutate(green = ifelse(LEED == 1 | Energystar == 1, 1, 0))%>%
  group_by(green) %>%
  summarize(yhat_mean = mean(predicted_yearly_rev))

ggplot(data=test_summ) + 
  geom_col(mapping=aes(x=green, y=yhat_mean)) +
  scale_x_discrete("green")

test_summ 



#Exercise3
library(lubridate)
library(ggplot2)
library(dplyr)
library(data.table)
library(ggrepel)
library(tidyverse)
library(devtools)

CAHousing <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/CAhousing.csv')

CAHousing <- CAHousing %>%
  mutate(logmedianHouseValue = log(medianHouseValue))
  
#real data
ggplot(data = CAHousing)+
  geom_point(aes(x = latitude, y = longitude, color = medianHouseValue))


CAHousing_split = initial_split(CAHousing)

# training and testing sets
n = nrow(CAHousing)
n_train = floor(0.8*n)
n_test = n - n_train
train_cases = sample.int(n, size=n_train, replace=FALSE)
CAHousing_train = training(CAHousing_split)
CAHousing_test = testing(CAHousing_split)


forest_house = randomForest(medianHouseValue ~ . - logmedianHouseValue,
                       data=CAHousing_train)

yhat_test = predict(forest_house, CAHousing_test)
plot(yhat_test, CAHousing_test$medianHouseValue)

rmse(forest_house, CAHousing_test)

plot(forest_house)
varImpPlot(forest_house)
 
#predicted plot on test data
ggplot(data = CAHousing_test)+
  geom_point(aes(x = latitude, y = longitude, color = yhat_test))

devtools::install_github("dkahle/ggmap")
register_google(key = "AIzaSyDU9cGUAPlPWFjHIVN5BgyOx4WF1FSEFLs", write = TRUE)

get_map()
ggmap(get_map())

meanlon = mean(CAHousing$longitude)
meanlat = mean(CAHousing$latitude)

p <- ggmap(get_googlemap(center = c(lon = -122, lat = 38),
                         zoom = 6, scale = 2,
                         maptype ='terrain',
                         color = 'color'))

#realvalues
p + geom_point(aes(x = longitude, y = latitude,  colour = medianHouseValue), data = CAHousing, size = 1) 

#predicted values
p + geom_point(aes(x = longitude, y = latitude,  colour = yhat_test), data = CAHousing_test, size = 1) 

#chart residuals

CAHousing_resids <- CAHousing_test %>%
  mutate(residual = medianHouseValue - yhat_test)

p + geom_point(aes(x = longitude, y = latitude,  colour = residual), data = CAHousing_resids, size = 1) 



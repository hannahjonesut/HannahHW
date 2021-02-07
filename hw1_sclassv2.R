library(tidyverse)
library(ggplot2)
library(rsample)  # for creating train/test splits
library(caret)
library(modelr)
library(parallel)

sclass <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/sclass.csv") 
head(sclass)

sclass_350 = sclass %>%
  filter(trim == "350")

k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)
rmse_out = foreach(i=1:10, .combine='rbind') %dopar% {
  sclass350_split =  initial_split(sclass_350, prop=0.9)
  sclass350_train = training(sclass350_split)
  sclass350_test  = testing(sclass350_split)
  this_rmse = foreach(k = k_grid, .combine='c') %do% {
    # train the model and calculate RMSE on the test set
    knn_model = knnreg(price ~ mileage, data=sclass350_train, k = k, use.all=TRUE)
    modelr::rmse(knn_model, sclass350_test)
  }
  data.frame(k=k_grid, rmse=this_rmse)
}
rmse_out = arrange(rmse_out, k)

ggplot(rmse_out) + geom_boxplot(aes(x=factor(k), y=rmse)) + theme_bw(base_size=7)

# Min error at k=15, max range is k=125
sclass350_split =  initial_split(sclass_350, prop=0.9)
sclass350_train = training(sclass350_split)
sclass350_test  = testing(sclass350_split)
knn125 = knnreg(price ~ mileage, data=sclass350_train, k=125)
rmse(knn125, sclass350_test)

####
# plot the fit
####

# attach the predictions to the test data frame
sclass350_test = sclass350_test%>%
  mutate(price350_pred = predict(knn125, sclass350_test))

p_test = ggplot(data = sclass350_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) 

p_test

# now add the predictions
p_test + geom_line(aes(x = mileage, y = price350_pred), color='red', size=1.5)



#for 65AMG

sclass_65= sclass %>%
  filter(trim == "65 AMG")

k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250)
rmse_out65 = foreach(i=1:10, .combine='rbind') %dopar% {
  sclass65_split =  initial_split(sclass_65, prop=0.9)
  sclass65_train = training(sclass65_split)
  sclass65_test  = testing(sclass65_split)
  this_rmse65 = foreach(k = k_grid, .combine='c') %do% {
    # train the model and calculate RMSE on the test set
    knn_model = knnreg(price ~ mileage, data=sclass65_train, k = k, use.all=TRUE)
    modelr::rmse(knn_model, sclass65_test)
  }
  data.frame(k=k_grid, rmse=this_rmse65)
}
rmse_out65 = arrange(rmse_out65, k)

ggplot(rmse_out65) + geom_boxplot(aes(x=factor(k), y=rmse)) + theme_bw(base_size=7)

# Min error at k=15, max range is k=60
sclass65_split =  initial_split(sclass_65, prop=0.9)
sclass65_train = training(sclass65_split)
sclass65_test  = testing(sclass65_split)
knn60 = knnreg(price ~ mileage, data=sclass65_train, k=60)
rmse(knn60, sclass65_test)

####
# plot the fit
####

# attach the predictions to the test data frame
sclass65_test = sclass65_test%>%
  mutate(price65_pred = predict(knn60, sclass65_test))

p_test = ggplot(data = sclass65_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) 

p_test

# now add the predictions
p_test + geom_line(aes(x = mileage, y = price65_pred), color='red', size=1.5)



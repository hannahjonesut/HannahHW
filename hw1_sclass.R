library(tidyverse)
library(ggplot2)
library(rsample)  # for creating train/test splits
library(caret)
library(modelr)
library(parallel)

sclass = sclass
head(sclass)

sclass_350 = sclass %>%
  filter(trim == "350")

# Make a train-test split
sclass350_split =  initial_split(sclass_350, prop=0.9)
sclass350_train = training(sclass350_split)
sclass350_test  = testing(sclass350_split)

sclass350_folds = crossv_kfold(sclass_350, k=K_folds)

models = map(sclass350_folds$train, ~ knnreg(price ~ mileage, k=100, data = ., use.all=FALSE))

# map the RMSE calculation over the trained models and test sets simultaneously
errs = map2_dbl(models, sclass350_folds$test, modelr::rmse)

# note:
#  - map2 means map over two inputs simultaneously
#  - _dbl means return the result as a vector of real numbers ("doubles")

mean(errs)
sd(errs)/sqrt(K_folds)   # approximate standard error of CV error


# so now we can do this across a range of k
k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)

# Notice we use the same folds for each value of k
# this is important, otherwise we're not comparing
# models across the same train/test splits


cv_grid = foreach(k = k_grid, .combine='rbind') %dopar% {
  models = map(sclass350_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, sclass350_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(K_folds))
} %>% as.data.frame

head(cv_grid)

# plot means and std errors versus k
ggplot(cv_grid) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# Min error at k=15, max range is k=70
knn70 = knnreg(price ~ mileage, data=sclass350_train, k=70)
rmse(knn70, sclass350_test)

####
# plot the fit
####

# attach the predictions to the test data frame
sclass350_test = sclass350_test%>%
  mutate(price350_pred = predict(knn70, sclass350_test))

p_test = ggplot(data = sclass350_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) 

p_test

# now add the predictions
p_test + geom_line(aes(x = mileage, y = price350_pred), color='red', size=1.5)



#for 63AMG

sclass_63= sclass %>%
  filter(trim == "63 AMG")

# Make a train-test split
sclass63_split =  initial_split(sclass_63, prop=0.9)
sclass63_train = training(sclass63_split)
sclass63_test  = testing(sclass63_split)

sclass63_folds = crossv_kfold(sclass_63, k=K_folds)

# map the model-fitting function over the training sets
models = map(sclass63_folds$train, ~ knnreg(price ~ mileage, k=100, data = ., use.all=FALSE))
# "map" transforms an input by applying a function to
# each element of a list or atomic vector and returning
# an object of the same length as the input.

# map the RMSE calculation over the trained models and test sets simultaneously
errs = map2_dbl(models, sclass65_folds$test, modelr::rmse)

# note:
#  - map2 means map over two inputs simultaneously
#  - _dbl means return the result as a vector of real numbers ("doubles")

mean(errs)
sd(errs)/sqrt(K_folds)   # approximate standard error of CV error


# so now we can do this across a range of k
k_grid63 = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200)

# Notice we use the same folds for each value of k
# this is important, otherwise we're not comparing
# models across the same train/test splits
cv_grid = foreach(k = k_grid63, .combine='rbind') %dopar% {
  models = map(sclass65_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, sclass63_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(K_folds))
} %>% as.data.frame

head(cv_grid)

# plot means and std errors versus k
ggplot(cv_grid) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()


# error bottoms out at k=10, max in range in k=30
knn30 = knnreg(price ~ mileage, data=sclass63_train, k=30)
rmse(knn30, sclass63_test)

####
# plot the fit
####

# attach the predictions to the test data frame
sclass63_test = sclass63_test%>%
  mutate(price63_pred = predict(knn30, sclass63_test))

p_test = ggplot(data = sclass63_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) 

p_test

# now add the predictions
p_test + geom_line(aes(x = mileage, y = price63_pred), color='red', size=1.5)



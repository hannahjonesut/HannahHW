library(tidyverse)
library(ggplot2)

capmetro <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/capmetro_UT.csv")

capmetro = mutate(capmetro,
                     day_of_week = factor(day_of_week,
                                          levels=c("Mon", "Tue", "Wed","Thu", "Fri", "Sat", "Sun")),
                     month = factor(month,
                                    levels=c("Sep", "Oct","Nov")))

#partone
avgboarding<- capmetro %>%
  group_by(hour_of_day, day_of_week, month)%>%
  summarize(meanboard = mean(boarding))

ggplot(data=avgboarding)+
  geom_line(aes(x = hour_of_day, y = meanboard, group = month, color = month))+
  facet_wrap(~day_of_week)+
  xlab("Hour of the Day")+
  ylab("Average Riders")

#parttwo

tempvboard<- capmetro %>%
  group_by(hour_of_day, weekend)

ggplot(data=tempvboard)+
  geom_point(aes(x=temperature, y=boarding, color = weekend))+
  facet_wrap(~hour_of_day)


#Problem 2

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
data(SaratogaHouses)

#create indicator variables for all string inputs (heating, fuel, sewer, new build, waterfront, central air)
saratoga_fe = SaratogaHouses %>%
  mutate(gas_fuel = ifelse(fuel == "gas", 1, 0), oil_fuel = ifelse(fuel == "oil", 1, 0), electric_fuel = ifelse(fuel == "electric", 1, 0)
        , waterfront = ifelse(waterfront == "Yes", 1, 0), newConstruction = ifelse(newConstruction == "Yes", 1, 0), 
        hotair_heat = ifelse(heating == "hot air", 1, 0), electric_heat = ifelse(heating == "electric", 1, 0), water_heat = ifelse(heating == "hot water / steam", 1, 0),
        septic_sewage = ifelse(sewer == "septic", 1, 0), comm_sewage = ifelse(sewer == "public/commercial", 1, 0), no_sewage = ifelse(sewer == "none", 1, 0),
        centralAir = ifelse(centralAir == "Yes", 1, 0), agesq = age^2, highed = ifelse(pctCollege >= 75, 1, 0), lprice = log(price), logland = log(landValue))
                                                                                                        
saratoga_scale= saratoga_fe%>%
  mutate_at(c('price','age', 'newConstruction', 'bathrooms', 'rooms', 'waterfront', 'centralAir', 'landValue', 'lotSize','livingArea','bedrooms','rooms'),
            funs(c(scale(.))))

#training data model
saratoga_split = initial_split(saratoga_fe, prop = 0.8)
saratoga_train = training(saratoga_split)
saratoga_test = testing(saratoga_split)

#model to beat

lm_medium = lm(price ~ lotSize + age + livingArea + pctCollege + bedrooms + 
                 fireplaces + bathrooms + rooms + heating + fuel + centralAir, data=saratoga_train)
coef(lm_medium) %>% round(0)
rmse(lm_medium, saratoga_test)

rmsemed_out = foreach(i=1:10, .combine='rbind') %do% {
  saratoga_split = initial_split(saratoga_fe, prop = 0.8)
  saratoga_train = training(saratoga_split)
  saratoga_test = testing(saratoga_split)
  # train the model and calculate RMSE on the test set
  lm_medium = lm(price ~ lotSize + age + livingArea + pctCollege + bedrooms + 
                   fireplaces + bathrooms + rooms + heating + fuel + centralAir, data=saratoga_train)
  this_rmse = modelr::rmse(lm_medium, saratoga_test)
}
rmsemed_out_mean=mean(rmsemed_out)
rmsemed_out_mean

#working model

workmod = lm_robust(price~ age + newConstruction + bathrooms+ rooms + waterfront + centralAir + landValue*lotSize + 
                      livingArea*bedrooms + livingArea*rooms , data = saratoga_train)
coef(workmod) %>% round(2)
rmse(workmod, saratoga_test)

rmselm_out = foreach(i=1:10, .combine='rbind') %do% {
  saratoga_split = initial_split(saratoga_scale, prop = 0.8)
  saratoga_train = training(saratoga_split)
  saratoga_test = testing(saratoga_split)
    # train the model and calculate RMSE on the test set
  workmod = lm_robust(price~ age + newConstruction + bathrooms+ rooms + waterfront + centralAir + landValue*lotSize + 
                          livingArea*bedrooms + livingArea*rooms , data = saratoga_train)
  this_rmse = modelr::rmse(workmod, saratoga_test)
  }
rmselm_out_mean=mean(rmselm_out)
rmselm_out_mean

#KNN
#NEED TO Z-SCORE ALL VARIABLES
  
k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200)
rmse_out = foreach(i=1:10, .combine='rbind') %dopar% {
  saratoga_split = initial_split(saratoga_scale, prop = 0.8)
  saratoga_train = training(saratoga_split)
  saratoga_test = testing(saratoga_split)
  this_rmse = foreach(k = k_grid, .combine='c') %do% {
    # train the model and calculate RMSE on the test set
    knn_model = knnreg(price ~ age + newConstruction + bathrooms + rooms + waterfront + centralAir + landValue+lotSize + 
                         livingArea + bedrooms + rooms, data=saratoga_train, k = k, use.all=TRUE)
    modelr::rmse(knn_model, saratoga_test)
  }
  data.frame(k=k_grid, rmse=this_rmse)
}
rmse_out_knn = arrange(rmse_out, k)

mean_rmse_knn <- rmse_out_knn%>%
  group_by(k)%>%
  summarize(mean = mean(rmse))



#number3

german_credit <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/german_credit.csv")

#Make a bar plot of default probability by credit history, and build a logistic 
#regression model for predicting default probability, using the variables 
#duration + amount + installment + age + history + purpose + foreign

history_bar = german_credit %>%
  group_by(history)%>%
  summarize(n=n(), sumdefault = sum(Default), default_prob = sum(Default)/n, meandef = mean(Default))

ggplot(data = history_bar)+
  geom_col(aes(x=history, y=default_prob))+
  xlab("Credit History")+
  ylab("Probability of Default")

default_split = initial_split(german_credit, prop = 0.8)
default_train = training(default_split)
default_test = testing(default_split)

cred_default = glm(Default ~ duration + amount + installment + age + history + purpose + foreign, data=default_split, family=binomial)

phat_credit = predict(cred_default, default_test, type='response')
yhat_credit = ifelse(phat_credit > 0.5, 1, 0)
confusion_out_credit = table(y = default_test$Default, yhat = yhat_credit)

confusion_out_credit
sum(diag(confusion_out_credit))/sum(confusion_out_credit)

#number 4

#load data
hotels_dev <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/hotels_dev.csv")
hotels_val <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/hotels_val.csv")

#make train/test splits
hotels_split =  initial_split(hotels_dev, prop=0.8)
hotels_train = training(hotels_split)
hotels_test  = testing(hotels_split)

#baseline model 1 with market_segment, adults, customer_type, and is_repeated_guest 
#OH Q
base1 = glm(children~market_segment+adults+customer_type+is_repeated_guest, data = hotels_train)
coef(base1) %>% round(2)
rmse(base1, hotels_test)

phat_test_logit_hotels = predict(base1, hotels_test, type='response')
yhat_test_logit_hotels = ifelse(phat_test_logit_hotels > 0.5, 1, 0)
confusion_out_base1 = table(y = hotels_test$children,
                            yhat = yhat_test_logit_hotels)
confusion_out_base1
sum(diag(confusion_out_base1))/sum(confusion_out_base1)

#baseline 2 uses all the possible predictors except the arrival_date 
base2 = lm(children ~ . - arrival_date, data = hotels_train)
coef(base2) %>% round(2)
rmse(base2, hotels_test)

phat_test_logit_hotels = predict(base2, hotels_test, type='response')
yhat_test_logit_hotels = ifelse(phat_test_logit_hotels > 0.5, 1, 0)
confusion_out_base2= table(y = hotels_test$children,
                            yhat = yhat_test_logit_hotels)
confusion_out_base2
sum(diag(confusion_out_base2))/sum(confusion_out_base2)

#baseline 3 building however want
library(gamlr)

scx = model.matrix(children ~ .-1, data=hotels_dev) # do -1 to drop intercept!
scy = hotels_dev$children
sccvl = cv.gamlr(scx, scy, nfold = 20, family="binomial", verb = TRUE)
#plot(sccvl, select="min")

#scb.min = coef(sccvl, select = "min")
#log(sccvl$lambda.min)
#sum(scb.min !=0) 

scbeta = coef(sccvl)
scbeta

base3hand = lm(children~ hotel+lead_time+adults+meal+market_segment+distribution_channel+is_repeated_guest+
                 previous_bookings_not_canceled+reserved_room_type+booking_changes+customer_type+average_daily_rate+
                 total_of_special_requests+arrival_date, data = hotels_dev)

phat_test_logit_hotels = predict(base3hand, hotels_test, type='response')
yhat_test_logit_hotels = ifelse(phat_test_logit_hotels > 0.5, 1, 0)
confusion_out_base3 = table(y = hotels_test$children,
                            yhat = yhat_test_logit_hotels)
confusion_out_base3
sum(diag(confusion_out_base3))/sum(confusion_out_base3)#out-of-sample accuracy

#model validation

library(foreach)

hotels_splitv =  initial_split(hotels_val, prop=0.8)
hotels_trainv = training(hotels_split)
hotels_testv  = testing(hotels_split)

#pick best
phat_test_base3 = predict(base3hand, hotels_testv, type='response')

thresh_grid = seq(0.15, 0.05, by=-0.001)

roc_curve_hotels = foreach(thresh = thresh_grid, .combine='rbind') %do% {
  yhat_test_v = ifelse(phat_test_base3 >= thresh, 1, 0)
  # FPR, TPR for linear model
  confusion_out_v = table(y = hotels_testv$children, yhat = yhat_test_v)
  out_lin = data.frame(model = "linear",
                       TPR = confusion_out_v[2,2]/sum(hotels_testv$children==1),
                       FPR = confusion_out_v[1,2]/sum(hotels_testv$children==0))
  rbind(out_lin)
} %>% as.data.frame()
ggplot(roc_curve_hotels) + 
  geom_line(aes(x=FPR, y=TPR)) + 
  labs(title="ROC curve") +
  theme_bw(base_size = 10)+
  xlim(0, 0.5)+
  ylim(0,1)

#use all val data?
phat_test_base32 = predict(base3hand, hotels_val, type='response')

thresh_grid = seq(0.15, 0.05, by=-0.001)

roc_curve_hotels = foreach(thresh = thresh_grid, .combine='rbind') %do% {
  yhat_test_v = ifelse(phat_test_base32 >= thresh, 1, 0)
  # FPR, TPR for linear model
  confusion_out_v = table(y = hotels_val$children, yhat = yhat_test_v)
  out_lin = data.frame(model = "linear",
                       TPR = confusion_out_v[2,2]/sum(hotels_val$children==1),
                       FPR = confusion_out_v[1,2]/sum(hotels_val$children==0))
  rbind(out_lin)
} %>% as.data.frame()
ggplot(roc_curve_hotels) + 
  geom_line(aes(x=FPR, y=TPR)) + 
  labs(title="ROC curve") +
  theme_bw(base_size = 10)+
  xlim(0, 0.5)

#validation step 2 
library(foreach)
# allocate to folds
N = nrow(hotels_val)
K = 20
fold_id = rep_len(1:K, N)  # repeats 1:K over and over again
fold_id = sample(fold_id, replace=FALSE) # permute the order randomly

base3hand_val = lm(children~ hotel+lead_time+adults+meal+market_segment+distribution_channel+is_repeated_guest+
                     previous_bookings_not_canceled+reserved_room_type+booking_changes+customer_type+average_daily_rate+
                     total_of_special_requests+arrival_date, data = hotels_val_folds)

hotels_val_folds <- hotels_val %>%
  mutate(fold_id = sample(fold_id, replace=FALSE), phat_val_test = predict(base3hand_val, hotels_val, type='response'), yhat_val_test = ifelse(phat_val_test > 0.5, 1, 0)) #%>%

fold_groups <- hotels_val_folds%>%
  group_by(fold_id)%>%
  summarize(prop_children = mean(children), prop_pred = mean(phat_val_test), count_children = sum(children), count_pred = sum(yhat_val_test), count_dif = count_children-count_pred)

ggplot(data = fold_groups)+
  geom_point(aes(x=fold_id, y=count_dif))+
  xlab('Fold ID')+
  ylab('Difference Between Predicted and Observed Children')

final_table<-data.frame(
  ID_folds = c(fold_groups$fold_id), 
  predicted = c(fold_groups$count_pred), 
  actual = c(fold_groups$count_children),
  difference = c(fold_groups$count_dif)
)

final_table %>%
  kable(
    col.names = c("Fold Number", "Predicted Children", "Actual Children", "Difference"),
    digits = 0,
    caption = "Children Epectations vs Reality"
  )%>%
  kable_classic(full_width = F, html_font = "Cambria")





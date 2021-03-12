### forward selection
lm0 = lm(price ~ 1, data=saratoga_train)
lm_forward = step(lm0, direction='forward',
                  scope=~(lotSize + age + landValue + bedrooms + fireplaces + bathrooms + waterfront + newConstruction + centralAir)^2)
coef(lm_forward) %>% round(0)
rmse(lm_forward, saratoga_test)

#LM
lmfe1 = lm(price ~ age + landValue + livingArea + bedrooms + bathrooms + rooms + waterfront + newConstruction + centralAir + gas_fuel + oil_fuel+ hotair_heat + electric_heat + septic_sewage + no_sewage + highed, data = saratoga_train)
coef(lmfe1) %>% round(0)
rmse(lmfe1, saratoga_test)

####
# Compare out-of-sample predictive performance
####

# Split into training and testing sets
saratoga_split = initial_split(SaratogaHouses, prop = 0.8)
saratoga_train = training(saratoga_split)
saratoga_test = testing(saratoga_split)

# Fit to the training data
# Sometimes it's easier to name the variables we want to leave out
# The command below yields exactly the same model.
# the dot (.) means "all variables not named"
# the minus (-) means "exclude this variable"
lm1 = lm(price ~ lotSize + bedrooms + bathrooms, data=saratoga_train)
lm2 = lm(price ~ . - pctCollege - sewer - waterfront - landValue - newConstruction, data=saratoga_train)
lm3 = lm(price ~ (. - pctCollege - sewer - waterfront - landValue - newConstruction)^2, data=saratoga_train)

coef(lm1) %>% round(0)
coef(lm2) %>% round(0)
coef(lm3) %>% round(0)

# Predictions out of sample
# Root mean squared error
rmse(lm1, saratoga_test)
rmse(lm2, saratoga_test)
rmse(lm3, saratoga_test)

# Can you hand-build a model that improves on all three?
# Remember feature engineering, and remember not just to rely on a single train/test split

lm1 = lm(price ~ lotSize + bedrooms + bathrooms, data=saratoga_train)
lm2 = lm(price ~ . - pctCollege - sewer - waterfront - landValue - newConstruction, data=saratoga_train)
lm3 = lm(price ~ (. - pctCollege - sewer - waterfront - landValue - newConstruction)^2, data=saratoga_train)



# plot the fit

# attach the predictions to the test data frame
saratoga_test = saratoga_test%>%
  mutate(price_pred = predict(knn20, saratoga_test))

p_test = ggplot(data = saratoga_test) + 
  geom_point(mapping = aes(x = ., y = price), alpha=0.2) 

#add predictions
p_test + geom_line(aes(x = mileage, y = price65_pred), color='red', size=1.5)+ 
  labs(
    title = "65 AMG Trim Price based on Mileage ",
    x="Mileage",
    y="Price"
  )


base3= lm(children ~ 1, data=hotels_train)
lm_forward = step(base3, scope=~(.)^2)
coef(lm_forward) %>% round(2)
rmse(lm_forward, hotels_test)

lm_big = lm(children ~ (hotel+lead_time+stays_in_weekend_nights+stays_in_week_nights+adults
                        +meal+market_segment+distribution_channel+is_repeated_guest+
                          previous_cancellations+previous_bookings_not_canceled+reserved_room_type
                        +booking_changes+deposit_type+days_in_waiting_list+
                          customer_type+average_daily_rate+total_of_special_requests)^2, data= hotels_train)
drop1(lm_big)

rmselm_out = foreach(i=1:10, .combine='rbind') %dopar% {
  saratoga_split = initial_split(saratoga_fe, prop = 0.8)
  saratoga_train = training(saratoga_split)
  saratoga_test = testing(saratoga_split)
  this_rmse = foreach(i = 1:10, .combine='c') %do% {
    # train the model and calculate RMSE on the test set
    workmod = lm_robust(price~ age + newConstruction + bathrooms+ rooms + waterfront + centralAir + landValue*lotSize + 
                          livingArea*bedrooms + livingArea*rooms , data = saratoga_train)
    modelr::rmse(workmod, saratoga_test)
  }
  data.frame(i=1:10, rmse=this_rmse)
}
ggplot(rmse_out) + geom_boxplot(aes(x=factor(k), y=rmse)) + theme_bw(base_size=7)+ 
  labs(
    title = "RMSE for Different K-values",
    x="K Values",
    y="RMSE"
  )

# Min error at k=6, max range is k=50
saratoga_split =  initial_split(saratoga_scale, prop=0.8)
saratoga_train = training(saratoga_split)
saratoga_test  = testing(saratoga_split)
knn50 = knnreg(price ~ age + newConstruction + bathrooms + rooms + waterfront + centralAir + landValue+lotSize + 
                 livingArea+bedrooms + rooms, data=saratoga_train, k=50)

saratoga_test = saratoga_test%>%
  mutate(price_pred = predict(knn50, saratoga_test))

p_test = ggplot(data = saratoga_test) + 
  geom_point(mapping = aes(x = ., y = price), alpha=0.2) 

rmselm_out=arrange(rmse_out, i)


cov_bal<-data.frame(
  Model = c("Medium Model", "Linear Model", "KNN Model"),
  RMSE_all = c('rmsemed_out_mean', 'rmsemlm_out_mean', mean_rmse_knn$mean)
)

cov_bal %>%
  kable(
    col.names = c("Mean Error (RMSE)"),
    digits = 3,
    caption = "Panel A Covariate Balance"
  )%>%
  kable_classic(full_width = F, html_font = "Cambria")


phat_val_test = predict(base3hand_val, hotels_val_folds, type='response')
yhat_val_test = ifelse(phat_val_test > 0.5, 1, 0)


foreach(i=1:20, .combine='rbind') %dopar%{
  if(fold_id == i)
    phat_val_test = predict(base3hand_val, hotels_val_folds, type='response')
  yhat_val_test = ifelse(phat_val_test > 0.5, 1, 0)
}

prop_children = mean(children)
count_children = sum(children)

c('yhat_val_test', 'phat_val_test', 'prop_children', 'count_children')


split_folds <- split(hotels_val_folds, fold_id)

foreach(i = 1:fold_id, .combine='rbind')%dopar%{
  phat_val_test = predict(base3hand_val, hotels_val_folds, type='response')
  yhat_val_test = ifelse(phat_val_test > 0.5, 1, 0)
}

childrenv= hotels_val$children
flds <- createFolds(childrenv, k = 20, list = TRUE, returnTrain = FALSE)
names(flds)[1] <- "train"


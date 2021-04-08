#boosting
boost1 = gbm(medianHouseValue ~ longitude + latitude + housingMedianAge + totalRooms + totalBedrooms + population + households + medianIncome, data=CAHousing_train, 
             interaction.depth=2, n.trees=500, shrinkage=.05)

plot(medianHouseValue ~ longitude + latitude + housingMedianAge + totalRooms + totalBedrooms + population + households + medianIncome, data=CAHousing_train)
points( latitude ~ longitude, data=CAHousing_train, pch=19, col=predict(boost1, n.trees=500))

yhat_boost_test = predict(boost1, CAHousing_test, n.trees=100)
rmse_boost = mean((CAHousing$medianHouseValue - yhat_boost_test)^2) %>% sqrt
rmse_boost

#real data
#ggplot(data = CAHousing)+
#  geom_point(aes(x = latitude, y = longitude, color = medianHouseValue))

#plot(forest_house)
#varImpPlot(forest_house)

#predicted plot on test data
#ggplot(data = CAHousing_test)+
# geom_point(aes(x = latitude, y = longitude, color = yhat_test))

#devtools::install_github("dkahle/ggmap")

#plot(yhat_test, CAHousing_test$medianHouseValue)

CAHousing <- CAHousing %>%
  mutate(logmedianHouseValue = log(medianHouseValue))
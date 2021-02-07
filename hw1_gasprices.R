library(tidyverse)
library(ggplot2)
gasprices <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/GasPrices.csv')

#A) Gas stations charge more if they lack direct competition in sight (boxplot).
#plot competitors vs price in box plot

ggplot(data=gasprices) + 
  geom_boxplot(aes(x=Competitors, y=Price))

#The boxplot suggests this hypothesis is true. The average price of gas at a gas 
#station without competition in sight is $0.03 higher than when competition is not present.

#B) The richer the area, the higher the gas price (scatter plot). scatter -> no pipe summarize
#plot income vs price

ggplot(data = gasprices) + 
  geom_point(mapping = aes(x = Income, y = Price)) 

#C) Shell charges more than other brands (bar plot). bar plot -> use pipe summarize
#brand vs price

# Let's store our one-group summary in a data frame called d1
d1 = gasprices %>%
  group_by(Brand) %>%
  summarize(avg_price = mean(Price),
            med_price = median(Price))
d1

# Now we can use d1 to make a barplot of average gas price by Brand.
# Use geom_col to make a barplot
ggplot(data = d1) + 
  geom_col(mapping = aes(x=Brand, y=avg_price))

#D) Gas stations at stoplights charge more (faceted histogram). 
#plot stoplight vs price

ggplot(data = gasprices) + 
  geom_histogram(aes(x=Price)) + 
  facet_wrap(~Stoplight) + 
  labs(
    title = "Gas Price based on Proximity to Stoplight",
    caption = "Data from xyz",
    x="Price of Gas",
    y="Density"
  )

#E) Gas stations with direct highway access charge more (your choice of plot).
#highway vs price

ggplot(data = gasprices) + 
  geom_boxplot(aes(x=Highway, y=Price)) + 
  labs(
    title = "Gas Price based on Proximity to Highway",
    caption = "Data from xyz",
    x="Direct Highway Access?",
    y="Price"
  )
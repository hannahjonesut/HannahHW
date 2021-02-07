library(tidyverse)
library(ggplot2)

ABIA <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/ABIA.csv") 
head(ABIA)

#Possible Questions: What is the most likely reason for a flight being canceled? 
#Does it vary by day of week?

cancel = ABIA %>%
  filter(Cancelled==1)%>%
  group_by(CancellationCode, DayOfWeek)%>%
  summarize(cancelled_flights=sum(Cancelled))

ggplot(data = cancel)+
  geom_col(aes(x=DayOfWeek, y = cancelled_flights))

#Predominate reason cancelled?

ggplot(data = cancel)+
  geom_col(aes(x=DayOfWeek, y = cancelled_flights))+
  facet_wrap(~CancellationCode)

#Where usually cancelled-- find a way to filter better
destination = ABIA%>%
  filter(Cancelled==1)%>%
  filter(Dest != "AUS")%>%
  group_by (Dest)%>%
  summarize(dest_cancel = sum(Cancelled))

ggplot(data = destination)+
  geom_col(aes(x=dest_cancel, y = Dest))

#dfw & DAL is highest cancelled.  Certain day of week worse?

time_dest = ABIA %>%
  filter(Dest == "DFW" | Dest == "DAL" | Dest == "ORD")%>%
  group_by(DayOfWeek, Dest)%>%
  summarize(dal_cancel = sum(Cancelled))

ggplot(data = time_dest) +
  geom_col(aes(x=DayOfWeek, y= dal_cancel)) +
  facet_wrap(~Dest)


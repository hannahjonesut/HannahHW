library(tidyverse)
library(ggplot2)
library(rsample)
library(caret)
library(modelr)
library(parallel)
library(foreach)
library(scales)
library(lubridate)
library(randomForest)
library(splines)
library(pdp)
library(LICORS)  # for kmeans++
library(foreach)
library(mosaic)
library(readr)
library(arules)  # has a big ecosystem of packages built around it
library(arulesViz)
library(igraph)
library(data.table)
library(tm) 
library(tidyverse)
library(slam)
library(proxy)
library(reshape2)

#PROBLEM 1
wine = read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/wine.csv')

wine$ID <- seq.int(nrow(wine))

wine<- wine%>%
  mutate(color = ifelse(color == 'red', 1, 0))

ggplot(wine) + 
  geom_point(aes(x=quality, y=alcohol, color= color))

wine_ID = wine %>%
  group_by(ID)%>%
  summarize_all(mean)%>%
  column_to_rownames(var = "ID")

pca_ID = prcomp(wine_ID, rank=2, scale=TRUE)
loadings_ID = pca_ID$rotation
scores_ID = pca_ID$x
summary(pca_ID)

qplot(scores_ID[,1], scores_ID[,2], xlab='Component 1', ylab='Component 2', color = wine_ID$color)

o1 = order(loadings_ID[,1], decreasing=TRUE)
colnames(wine)[head(o1,3)]
colnames(wine)[tail(o1,3)]

o2 = order(loadings_ID[,2], decreasing=TRUE)
colnames(wine)[head(o2,3)]
colnames(wine)[tail(o2,3)]

plot(pca_ID)

#Predict using PCA

wine_combined = data.frame(wine, pca_ID$x)

train_frac = 0.8
N = nrow(wine_combined)
N_train = floor(train_frac*N)
N_test = N - N_train
train_ind = sample.int(N, N_train, replace=FALSE) %>% sort
wine_train = wine_combined[train_ind,]
wine_test = wine_combined[-train_ind,]

forest_color = randomForest(color ~ PC1 + PC2,
                            data = wine_train)

yhat_forest_color = predict(forest_color, wine_test)
mean((yhat_forest_color - wine_test$color)^2) %>% sqrt

plot(forest_color)
varImpPlot(forest_color)


forest_quality = randomForest(quality ~ PC1 + PC2,
                            data = wine_train)

yhat_forest_qual = predict(forest_quality, wine_test)
mean((yhat_forest_qual - wine_test$quality)^2) %>% sqrt

plot(forest_quality)
varImpPlot(forest_quality)


#use clustering - KMEANS

wine_train = subset(wine, select = -c(color, quality, ID))

wine_train_scaled = scale(wine_train, center=TRUE, scale=TRUE)

# Extract the centers and scales from the rescaled data (which are named attributes)
mu = attr(wine_train_scaled,"scaled:center")
sigma = attr(wine_train_scaled,"scaled:scale")

# Run k-means with 2 clusters and 25 starts
clust1 = kmeans(wine_train_scaled, 2, nstart=25)

wine_clustered = data.frame(wine, clust1$cluster)

wine_clustered <- wine_clustered%>%
  mutate(predicted = ifelse(clust1.cluster == 2, 1, 0))

#RMSE of clustering
mean((wine_clustered$predicted - wine_clustered$color)^2) %>% sqrt

# What are the clusters?
#clust1$center  # not super helpful
#clust1$center[1,]*sigma + mu
#clust1$center[2,]*sigma + mu



# A few plots with cluster membership shown
# qplot is in the ggplot2 library
qplot(color, residual.sugar, data=wine, color=factor(clust1$cluster))

#PROBLEM 2-- clustering to understand groups of tweeters

library(stats)
library(philentropy)

social_marketing <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/social_marketing.csv', row.names = 1)

summary(social_marketing)
#center and scale
X = scale(social_marketing, center=TRUE, scale=TRUE)
mu = attr(X,"scaled:center")
sigma = attr(X,"scaled:scale")

tweet_dist = distance(X, method = 'euclidean')
hier_tweet = hclust(tweet_dist, method = 'average')



#kmeans clustering
clust1 = kmeans(X, 4, nstart=25)

clust1$center  # not super helpful
clust1$center[1,]*sigma + mu
clust1$center[2,]*sigma + mu
clust1$center[3,]*sigma + mu
clust1$center[4,]*sigma + mu

#cluster 1 is travel and news
qplot(travel, news, data=social_marketing, color=factor(clust1$cluster))
qplot(current_events, news, data=social_marketing, color=factor(clust1$cluster))

#Cluster 4 all over these, very active
qplot(cooking, home_and_garden, data=social_marketing, color=factor(clust1$cluster))
qplot(eco, outdoors, data=social_marketing, color=factor(clust1$cluster))
qplot(personal_fitness, beauty, data=social_marketing, color=factor(clust1$cluster))

#cluster 2
qplot(school, parenting, data=social_marketing, color=factor(clust1$cluster))
qplot(parenting, cooking, data=social_marketing, color=factor(clust1$cluster))



#seems like health and nutrition cluster is most active

#Problem 3
groceries <- read_lines('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/groceries.txt', skip = 0, n_max = -1L)

groceries <- as.data.frame(groceries)

head(groceries)

#groceries$cart <- seq.int(nrow(groceries))

lists <- strsplit(groceries$groceries, split = ",")
all_lists = lapply(lists, unique)
listtrans = as(all_lists, "transactions")

summary(listtrans)

groceryrules = apriori(listtrans, 
                     parameter=list(support=.005, confidence=.1, maxlen=8))

arules::inspect(groceryrules)

#LIFT = increase in probability of what happens on RHS given the LHS occurs
#Confidence = probability rhs happens given lhs
#support = proportion of times it occured (occured in cart)/total carts

arules::inspect(subset(groceryrules, lift > 4))
arules::inspect(subset(groceryrules, confidence > 0.6))
arules::inspect(subset(groceryrules, lift > 3 & confidence > 0.4))

plot(groceryrules)

sub1 = subset(groceryrules, subset=confidence > 0.25 & support > 0.01)
summary(sub1)
plot(sub1, method='graph')
?plot.rules

plot(head(sub1, 100, by='lift'), method='graph')

saveAsGraph(sub1, file = "groceryrules.graphml")

#Problem 4

train_dir = Sys.glob(paths = '/Users/hannahjones/Documents/GitHub/ECO395M/data/ReutersC50/C50train/*')
train_dir = train_dir[c(1:50)]
read_files = NULL
labels = NULL
for(writer in train_dir){
  author = substring(writer, first = 1)
  article = Sys.glob(paste0(writer,'/*.txt'))
  read_files = append(read_files, article)
  labels = append(labels, rep(author, length(article)) )
}


readerPlain = function(fname){
  readPlain(elem=list(content=readLines(fname)), 
            id=fname, language='en') }

## create a text mining 'corpus' with: 
documents_raw = Corpus(DirSource(train_dir))

## Some pre-processing/tokenization steps.

train_docs = documents_raw 
train_docs = tm_map(train_docs, content_transformer(tolower))
train_docs = tm_map(train_docs, content_transformer(removeNumbers)) 
train_docs = tm_map(train_docs, content_transformer(removePunctuation))
train_docs = tm_map(train_docs, content_transformer(stripWhitespace)) 
train_docs = tm_map(train_docs, content_transformer(removeWords), stopwords("SMART"))

## create a doc-term-matrix, 2500 docs, 31423 terms
DTM_train = DocumentTermMatrix(train_docs)

## Finally, drop those terms that only occur in one or two documents, 3076 terms
DTM_train = removeSparseTerms(DTM_train, 0.96)
tf_idf_mat = weightTfIdf(DTM_train)

# Data frame of 2500 variables and 641 variables (The first matrix is completed)
training_mat <- as.matrix(tf_idf_mat)

#Clean the label names from before
author_names = labels %>%
  { strsplit(., '/', fixed=TRUE) } %>%
  { lapply(., tail, n=1) } %>%  
  { lapply(., paste0, collapse = '') } %>%
  unlist

#rename
all_files = lapply(read_files, readerPlain)
names(all_files) = author_names

#training_df <- data.frame(c(training_df, author_names))


#repeat all for test directory

test_dir = Sys.glob(paths = '/Users/hannahjones/Documents/GitHub/ECO395M/data/ReutersC50/C50test/*')
test_dir = test_dir[c(1:50)]
read_files1 = NULL
labels1 = NULL

for(writer1 in test_dir){
  author1 = substring(writer1, first = 69)
  article1 = Sys.glob(paste0(writer1,'/*.txt'))
  read_files1 = append(read_files1, article1)
  labels1 = append(labels1, rep(author1, length(article1)) )
}

all_files1 = lapply(read_files1, readerPlain)
#names(all_files1)= read_files1
#names(all_files1) = sub('.txt', '', names(all_files1))

## once you have documents in a vector, you 
## create a text mining 'corpus' with: 
documents_raw1 = Corpus(DirSource(test_dir))

## Some pre-processing/tokenization steps.
## tm_map just maps some function to every document in the corpus

test_docs= documents_raw1 
test_docs = tm_map(test_docs, content_transformer(tolower))
test_docs = tm_map(test_docs, content_transformer(removeNumbers)) 
test_docs = tm_map(test_docs, content_transformer(removePunctuation))
test_docs = tm_map(test_docs, content_transformer(stripWhitespace)) 
test_docs = tm_map(test_docs, content_transformer(removeWords), stopwords("SMART"))

## create a doc-term-matrix
DTM_test = DocumentTermMatrix(test_docs, control = list(dictionary = Terms(DTM_train)))
tf_idf_test = weightTfIdf(DTM_test)
DTM_test<-as.matrix(tf_idf_test)

#testing matrix
testing_mat <- as.matrix(DTM_test)

#Clean the label names from before
author_names1 = NULL
author_names1 = labels1 %>%
  { strsplit(., '/', fixed=TRUE) } %>%
  { lapply(., tail, n=1) } %>%  
  { lapply(., paste0, collapse = '') } %>%
  unlist

names(all_files1) = author_names1

#DTM_train1 = removeSparseTerms(DTM_train, 0.95)
#DTM_test1 = removeSparseTerms(DTM_test, 0.95)

training_df1 <- data.frame(as.matrix(DTM_train), stringsAsFactors=FALSE)
testing_df1 <- data.frame(as.matrix(DTM_test), stringsAsFactors=FALSE)

#remove zero columns
training_df1<-training_df1[,which(colSums(training_df1) != 0)] 
testing_df1<-testing_df1[,which(colSums(testing_df1) != 0)]

#only keep matching columns
testing_df1 = testing_df1[,intersect(colnames(testing_df1),colnames(training_df1))]
training_df1 = training_df1[,intersect(colnames(testing_df1),colnames(training_df1))]

####
# Dimensionality reduction
####

mod_pca = prcomp(training_df1,scale=TRUE)
pred_pca=predict(mod_pca,newdata = testing_df1)

plot(mod_pca, type = 'line') 

var <- apply(mod_pca$x, 2, var)  
prop <- var / sum(var)
cumsum(prop) # 75% of variance explained by PC 1 - 333
plot(cumsum(mod_pca$sdev^2/sum(mod_pca$sdev^2)))

train_author = data.frame(mod_pca$x[,1:333])
train_author['author']=author_names
train_load = mod_pca$rotation[,1:333]

test_author_pre <- scale(testing_df1) %*% train_load
test_author <- as.data.frame(test_author_pre)
test_author['author']=author_names1

# run a random forest using PCA variables in train_author

train_author$author = factor(train_author$author) 
test_author$author = factor(test_author$author) 

author_forest = randomForest(author ~ .,
                              data = train_author)

yhat_author = predict(author_forest, test_author)

comp_table<-as.data.frame(table(yhat_author,test_author$author))
predicted<-yhat_author
actual<-as.factor(test_author$author)
comp_table<-as.data.frame(cbind(actual,predicted))
comp_table$flag<-ifelse(comp_table$actual==comp_table$predicted,1,0)
sum(comp_table$flag)
sum(comp_table$flag)*100/nrow(comp_table)

plot(author_forest)
varImpPlot(author_forest)












wine_color = wine %>%
  group_by(color)%>%
  select(-ID)%>%
  summarize_all(mean)%>%
  column_to_rownames(var = "color")

wine_qual = wine %>%
  group_by(quality)%>%
  select(-ID)%>%
  summarize_all(mean)%>%
  column_to_rownames(var = "quality")

pca_color = prcomp(wine_color, rank=5, scale=TRUE)
loadings_color = pca_color$rotation
scores_color = pca_color$x
summary(pca_color)

pca_qual = prcomp(wine_qual, rank=5, scale=TRUE)
loadings_qual = wine_qual$rotation
scores_qual = wine_qual$x
summary(pca_qual)


dat = readLines("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/groceries.txt")
dat = as.data.frame(do.call(rbind,strsplit(dat, split = ",")), stringsAsFactors=FALSE)
groceries = lapply(dat, unique)

grocery_df<- data.frame(cart = rep(groceries$cart, sapply(lists, length)), V2 = unlist(lists))

authors = dir('/Users/hannahjones/Documents/GitHub/ECO395M/data/ReutersC50/C50train')
authors_df = as.data.frame(authors)


#joeys

readerPlain = function(fname){
  readPlain(elem=list(content=readLines(fname)), 
            id=fname, language='en') }

## Rolling two directories together into a single training corpus
train_dirs = Sys.glob('/Users/josephherrera/Desktop/ECO395M/data/ReutersC50/C50train/*')
train_dirs = train_dirs[c(1:50)]
file_list = NULL
labels_train = NULL
for(author in train_dirs) {
  author_name = substring(author, first=1)
  files_to_add = Sys.glob(paste0(author, '/*.txt'))
  file_list = append(file_list, files_to_add)
  labels_train = append(labels_train, rep(author_name, length(files_to_add)))
}
train_dirs

corpus_train = Corpus(DirSource(train_dirs)) 

corpus_train = corpus_train %>% tm_map(., content_transformer(tolower)) %>% 
  tm_map(., content_transformer(removeNumbers)) %>% 
  tm_map(., content_transformer(removeNumbers)) %>% 
  tm_map(., content_transformer(removePunctuation)) %>%
  tm_map(., content_transformer(stripWhitespace)) %>%
  tm_map(., content_transformer(removeWords), stopwords("SMART"))



DTM_train = DocumentTermMatrix(corpus_train)
DTM_train # some basic summary statistics

# Parse out words in the bottom five percent of all terms
DTM_train2 = removeSparseTerms(DTM_train, 0.95)
DTM_train2

# Data frame of 2500 variables and 641 variables (The first matrix is completed)
DF_train <- data.frame(as.matrix(DTM_train2), stringsAsFactors=FALSE)


# I need a vector of labels
labels_train = append(labels_train, rep(author_name, length(files_to_add)))

#Clean the label names
author_names = labels_train %>%
  { strsplit(., '/', fixed=TRUE) } %>%
  { lapply(., tail, n=2) } %>%
  { lapply(., paste0, collapse = '') } %>%
  unlist

author_names = as.data.frame(author_names)

author_names = gsub("C([0-9]+)train", "\\1", author_names$author_names)
author_names = gsub("([0-9]+)", "", author_names)

author_names = as.data.frame(author_names)



split_names <- colsplit(mynames, "(?<=\\p{L})(?=[\\d+$])", c("Author", "File"))

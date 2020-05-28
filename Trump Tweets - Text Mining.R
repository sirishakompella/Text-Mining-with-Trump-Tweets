#set working directory
cname <- setwd("C:\\Users\\vchan\\Downloads\\Kompella\\6040\\Trump")
cname   
dir(cname)


##########Start Analysis#################################
#Load package "tm" and all the files you have downloaded
library(tm)

#Create Corpus after you create the Source
docs <- VCorpus(DirSource(cname))   
summary(docs)   

#Load details of any documents in the corpus
#for example, load the first document in corpus
inspect(docs[1])

writeLines(as.character(docs[[1]]))


#####Preprocessing####

#Remove numbers, capitalization, common words, punctuation, and otherwise prepare your texts for analysis.

docs <- tm_map(docs,removePunctuation) 


for (j in seq(docs)) {
  docs[[j]] <- gsub("/", " ", docs[[j]])
  docs[[j]] <- gsub("@", " ", docs[[j]])
  docs[[j]] <- gsub("\\|", " ", docs[[j]])
  docs[[j]] <- gsub("\u2028", " ", docs[[j]])
}

docs <- tm_map(docs, removeNumbers)  

docs <- tm_map(docs, tolower)   
docs <- tm_map(docs, PlainTextDocument)
DocsCopy <- docs
DocsCopy

writeLines(as.character(docs[[1]]))


docs <- tm_map(docs, removeWords, stopwords("english"))   
docs <- tm_map(docs, PlainTextDocument)
#Removing particular words
docs <- tm_map(docs, removeWords, c("syllogism", "tautology"))   

#Combining words that should stay together.for example, combine "inner", "city" as "inner-city" so you can analyze them together
for (j in seq(docs))
{
  docs[[j]] <- gsub("fake news", "fake_news", docs[[j]])
  docs[[j]] <- gsub("inner city", "inner-city", docs[[j]])
  docs[[j]] <- gsub("politically correct", "politically_correct", docs[[j]])
}
docs <- tm_map(docs, PlainTextDocument)

docs_st <- tm_map(docs, stemDocument)   
docs_st <- tm_map(docs_st, PlainTextDocument)
writeLines(as.character(docs_st[1]))

docs_stc <- tm_map(docs_st, stemCompletion, dictionary = DocsCopy, lazy=TRUE)
docs_stc <- tm_map(docs_st, PlainTextDocument)
writeLines(as.character(docs_stc[1]))

docs <- tm_map(docs, stripWhitespace)

docs <- tm_map(docs, PlainTextDocument)

writeLines(as.character(docs[[1]]))


#####Stage your data##########
#A document-term matrix or term-document matrix is a mathematical matrix that describes the frequency of terms that occur in a collection of documents. In a document-term matrix, rows correspond to documents in the collection and columns correspond to terms. 
dtm <- DocumentTermMatrix(docs)   
dtm 

#Transpose the matrix
tdm <- TermDocumentMatrix(docs)   
tdm  

#Organize terms by Frequency
freq <- colSums(as.matrix(dtm))   
length(freq)

ord <- order(freq) 

m <- as.matrix(dtm)   
dim(m) 
#Explore as csv
write.csv(m, file="DocumentTermMatrix.csv")   

#  Start by removing sparse terms:
dtms <- removeSparseTerms(dtm, 0.2) # This makes a matrix that is 20% empty space, maximum.   
dtms

# most and least frequently occurring words.
freq <- colSums(as.matrix(dtm)) 
#Check out the frequency of frequencies
head(table(freq), 20) #The resulting output is two rows of numbers. The top number is the frequency with which words appear and the bottom number reflects how many words appear that frequently. Here, considering only the 20 lowest word frequencies, we can see that 1602 terms appear only once. There are also a lot of others that appear very infrequently.

tail(table(freq), 20) # The ", 20" indicates that we only want the last 20 frequencies

#For a less, fine-grained look at term freqency we can view a table of the terms we selected when we removed sparse terms
freq <- colSums(as.matrix(dtms))   
freq 

#sort the most frequent words as decreasing order
freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)   
head(freq, 14) #select top 14

#create a data frame for next steps
wf <- data.frame(word=names(freq), freq=freq)   
head(wf)

#####Plot Word Frequency#########
library(ggplot2)#load package ggplot2
#Plot a histogram for words that appear at least 50 times
p <- ggplot(subset(wf, freq>50), aes(x = reorder(word, -freq), y = freq)) +geom_bar(stat = "identity") + theme(axis.text.x=element_text(angle=45, hjust=1))
p  

#####Calculate terms correlations#####
#identify the words that most highly correlate with that term. If words always appear together, then correlation=1.0
findAssocs(dtm, c("country" , "american"), corlimit=0.85) # specifying a correlation limit of 0.85. Feel free to change the words you want to check and correlation limit

findAssocs(dtm, c("immigration" , "jobs"), corlimit=0.95)

findAssocs(dtm, c("visas" , "deliver"), corlimit=0.95)

findAssocs(dtm, c("work" , "great"), corlimit=0.95)

findAssocs(dtm, c("protect" , "jobs"), corlimit=0.85)

findAssocs(dtm, c("borders" , "world"), corlimit=0.89)

findAssocs(dtm, c("disaster" , "vision"), corlimit=0.85)

findAssocs(dtm, c("american" , "brave"), corlimit=0.90)

findAssocs(dtm, c("taxpayers" , "womens"), corlimit=0.90)

findAssocs(dtm, c("jobs" , "illness"), corlimit=0.85)

findAssocs(dtm, c("budget" , "womens"), corlimit=0.95)

findAssocs(dtm, c("empowered" , "jobs"), corlimit=0.90)


#####Create word clouds######
# First load the package that makes word clouds in R.    
library(wordcloud)   
dtms <- removeSparseTerms(dtm, 0.15) # Prepare the data (max 15% empty space)   
freq <- colSums(as.matrix(dtm)) # Find word frequencies   
#dark2 <- brewer.pal(20, "Paired")
wordcloud(names(freq), freq, min.freq = 1, random.order=FALSE, max.words=100, rot.per=0.35, colors = brewer.pal(20, "Paired"))      


#####Hierarchal Clustering#####   
dtms <- removeSparseTerms(dtm, 0.15) # This makes a matrix that is only 15% empty space.
library(cluster)   
d <- dist(t(dtms), method="euclidian")   # First calculate distance between words
d
fit <- hclust(d=d, method="complete")    # Also try: method="ward.D"   
plot.new()
plot(fit, hang=-1)
groups <- cutree(fit, k=6)   # "k=" defines the number of clusters you are using   
rect.hclust(fit, k=6, border="red") # draw dendogram with red borders around the 5 clusters   

#####K-means clustering#####   
library(fpc)   
library(cluster)  
dtms <- removeSparseTerms(dtm, 0.15) # Prepare the data (max 15% empty space)   
d <- dist(t(dtms), method="euclidian")   
kfit <- kmeans(d, 2)   
clusplot(as.matrix(d), kfit$cluster, color=T, shade=T, labels=2, lines=0)  

kfit <- kmeans(d, 9)   
clusplot(as.matrix(d), kfit$cluster, color=T, shade=T, labels=2, lines=0)  

kfit <- kmeans(d, 3)   
clusplot(as.matrix(d), kfit$cluster, color=T, shade=T, labels=2, lines=0) 

kfit <- kmeans(d, 4)   
clusplot(as.matrix(d), kfit$cluster, color=T, shade=T, labels=2, lines=0) 


#kmeans - to determine optimal number of clusters
#look for "elbow" in plot of summed intra-cluster distances (withinss) as fn of k
#elbow plot shows 4 as the ideal no. of clusters
wss <- 2:10 #  k=2 to 10 (total no of files -1)
for (i in 2:10) wss[i] <- sum(kmeans(d,centers=i,nstart=25)$withinss)
plot(2:10, wss[2:10], type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares")




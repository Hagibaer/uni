setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")

# 2 load cleaned data
loans <- GetLoanDataset()

# get only numeric columns
numeric_idx <- sapply(loans, is.numeric)
loans_numeric <- loans[,numeric_idx]

# k-means clustering
set.seed(42)
cluster.object <- kmeans(loans_numeric, 5, iter.max=50, nstart=25)
# structure(cluster.object)
clusters <- cluster.object$cluster

# Empirically test for 'good' k
k_range <- 1:15
obj.values <- vector(mode = "numeric", length = length(k_range)) 
cluster.models <- vector(mode="list", length = length(k_range))

for(i in 1:length(k_range)){
  cluster.solution <- kmeans(loans_numeric, i, iter.max=50, nstart=25)
  obj.values[i] <- cluster.solution$tot.withinss 
  cluster.models[[i]] <- cluster.solution # two brackets because cluster.solution is list in list, stupid R here we go
}

# Plot sum of squares
if(!require("ggplot2")) install.packages("ggplot2")
library("ggplot2")

par(mar=c(2,2,2,2)) # some settings for the size
qplot(x = k_range, y=obj.values, geom = c("line", "point"), xlab = "Number of centers", ylab="sum of squares",
      main="elbow curve for k selections", colour="green") + guides(color=FALSE)

######### Decision Trees #######

if(!require("rpart")) install.packages("rpart")
library("rpart")
decision_tree <- rpart(formula = BAD ~ . ,data = loans, method = "class")
prediction.dt <- predict(decision_tree, newdata = loans, type = 'prob')[,2] # in sample

# get performance baseline
y <- as.numeric(loans$BAD) - 1 # -1  because R
brier.base <- sum((y-1)^2)/length(y)
brier.dt <- sum((y-prediction.dt)^2)/length(y)
brier.base
brier.dt

if(!require("rpart.plot")) install.packages("rpart.plot")
library("rpart.plot")
prp(decision_tree, extra = 104, border.col = 0, box.palette = "auto")

dt.full <- rpart(formula = BAD ~ ., data=loans, method = "class", cp=0.005, minsplit = 3)
#prp(dt.full) 

dt.prunedLess <-rpart(formula = BAD ~ ., data = loans, method = "class", cp=0.005, minbucket=4)
dt.prunedMore <-rpart(formula = BAD ~ ., data = loans, method = "class", cp=0.02, minbucket=8)

prp(dt.prunedLess)
prp(dt.prunedMore)

# get predictions
prediction.dt.full <- predict(dt.full, newdata = loans, type = 'prob')[,2] # in sample
prediction.dt.less <- predict(dt.prunedLess, newdata = loans, type = 'prob')[,2] # in sample
prediction.dt.more <- predict(dt.prunedMore, newdata = loans, type = 'prob')[,2] # in sample

# Get brier scores
brier.full <- sum((y-prediction.dt.full)^2)/length(y)
brier.less <- sum((y-prediction.dt.less)^2)/length(y)
brier.more <- sum((y-prediction.dt.more)^2)/length(y)

brier.base
brier.full
brier.less
brier.more




#Set-up
setwd("C:/Users/Hagen/uni/DS")
source(file = "Rintro_HelperFunctions.R")
loans = GetLoanDataset(file="Loan_Data.csv")

# Linear regression
lr <- lm(dINC_A ~.-BAD, data=loans)


prepData <- model.matrix(dINC_A ~ .-BAD, data=loans)
head(prepData)

summary(lr)
coef(summary(lr))

pred.lr <- predict(lr, newdata=loans)
summary(pred.lr)
summary(loans$dINC_A)

MAE <- mean(abs(loans$dINC_A - pred.lr))
MAE


#### Clustering
idx_numeric <- sapply(loans, is.numeric)

kmeans <- kmeans(x=loans[idx_numeric], centers=5, iter.max = 50, nstart=25)
k_settings  <- c(seq(1,15))
obj_values  <- vector(length = 15)

kmeans['tot.withinss']

for(i in k_settings){
  cluster_solution <- kmeans(x=loans[idx_numeric], centers=i)
  obj_values[i] <- cluster_solution['tot.withinss']
}

## alternative
my.kMeans <- function(k){
  clu.sol <- kmeans(loans[idx_numeric], centers=k)
  return(clu.sol$tot.withinss)
}
obj_values <- sapply(k_settings, my.kMeans)

plot(x=k_settings, y=obj_values, type='l')
str(kmeans)



system.time({
  for(i in k_settings){
    cluster_solution <- kmeans(x=loans[idx_numeric], centers=i)
    obj_values[i] <- cluster_solution['tot.withinss']
  }
})


system.time({
  obj_values <- sapply(k_settings, my.kMeans)
})


## Train a tree model
library("rpart")
library("rpart.plot")

dt <- rpart(BAD ~ ., data = loans, method = "class")
summary(dt)

# Calculate performance according to brier score
pred.dt <- predict(dt, newdata= loans, type="prob")
y <- as.numeric(loans$BAD) -1
sum((y-pred.dt[,2])^2) / length(y)


prp(dt)
prp(dt, extra = 104, border.col = 0, box.palette = "auto")

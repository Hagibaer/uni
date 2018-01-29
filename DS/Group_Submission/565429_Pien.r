if(!require("pacman")) install.packages("pacman")
library("pacman")
pacman::p_load(tidyverse, rpart, glmnet, caTools, caret, hmeasure, plotROC, e1071, Information, klaR, reshape2)

setwd("C:/Users/hagen/uni/DS/Group_Submission")


set.seed(123)

############################
# Loading the data
############################
column.classes <- c(order_item_id = "factor",
                    order_date = "Date",
                    delivery_date = "Date",
                    item_id = "factor",
                    item_size = "factor",
                    item_color = "factor",
                    brand_id = "factor",
                    item_price = "numeric",
                    user_id = "factor",
                    user_title = "factor",
                    user_dob = "Date",
                    user_state = "factor",
                    user_reg_date = "Date",
                    return = "integer")
data.known.orig <- read.csv("BADS_WS1718_known.csv", colClasses = column.classes)
data.class.orig <- read.csv("BADS_WS1718_class.csv", colClasses = column.classes[1:13])

data.known.orig <- as.tibble(data.known.orig)
str(data.known.orig)
summary(data.known.orig)

##########################
# Preprocessing data
##########################
# Creates new variables
# - age (computed from today and user_dob)
# - days_until_delivery (computed from order_date and delivery_date)
# - free_item (if the price of the item was 0)
# - user_orders (no. of orders this user has made in total)
# - item_orders (no. of times this item has been ordered in total)
# - brand_orders (no. of times this brand has been ordered)
##########################
# Replaces NAs in age, days_until_delivery with median
##########################
# 
preprocess <- function(data.orig, response = TRUE) {
  # Recode missings and binary variables
  
  data.preprocessed <-
    data.orig %>%
    mutate(delivery_date = replace(delivery_date, delivery_date < as.Date("2005-01-01"), NA), 
           age = as.double(Sys.Date() - user_dob) / 365,
           days_until_delivery = as.double(delivery_date - order_date))
  # droplevels(data.known) # not working?
  
  if (response) {
    data.preprocessed <- data.preprocessed %>%
      mutate(return = factor(return, levels = c(0, 1), labels = c("not returned", "returned")))
  }
  
  summary(data.preprocessed)
  
  ggplot(data = data.preprocessed,
         mapping = aes(x = "", y = age)) + 
    geom_boxplot()
  
  # replace outliers from age by median age
  age.quantiles <- quantile(data.preprocessed$age, na.rm = TRUE, type = 7)
  age.iqr <- IQR(data.preprocessed$age, na.rm = TRUE)
  age.median <- median(data.preprocessed$age, na.rm = TRUE)
  data.preprocessed <- data.preprocessed %>% 
    mutate(age = replace(age,
                         age < age.quantiles[2] - 2 * age.iqr | age > age.quantiles[4] + 2 * age.iqr | is.na(age),
                         age.median),
           free_item = ifelse(item_price == 0, 1, 0),
           days_until_delivery = replace(days_until_delivery, days_until_delivery == 0, 1))
  
  ggplot(data = data.preprocessed,
         mapping = aes(x = "", y = age)) + 
    geom_boxplot()
  
  na.omit(data.preprocessed[data.preprocessed$delivery_date < data.preprocessed$order_date,])
  # do not exist
  na.omit(data.preprocessed[data.preprocessed$user_dob > data.preprocessed$order_date,])
  # do not exist
  
  data.preprocessed <- data.preprocessed %>%
    mutate(days_until_delivery = replace(days_until_delivery, is.na(days_until_delivery), median(days_until_delivery, na.rm = TRUE))) %>%
    group_by(user_id) %>%
    mutate(user_orders = n()) %>%
    ungroup() %>%
    group_by(item_id) %>%
    mutate(item_orders = n()) %>%
    ungroup() %>%
    group_by(brand_id) %>%
    mutate(brand_orders = n()) %>%
    ungroup()
  
  #data.known.delivered <- data.known %>% filter(!is.na(days_until_delivery))
  #data.known.not_delivered <- data.known %>% filter(is.na(days_until_delivery))
  
  #summary(data.known.delivered)
  #summary(data.known.not_delivered)
  
  #levels(data.known$item_size)
  
  #ggplot(data = data.known) +
  #  geom_bar(mapping = aes(x = item_size)) +
  #  theme(axis.text.x = element_text(angle = 90, hjust = 1))
  
  data.preprocessed <- data.preprocessed %>% dplyr::select(-user_dob, -delivery_date, -order_date, -user_reg_date, -order_item_id, -user_id)
  
  return(data.preprocessed)
}

## Preprocessing

data.known <- preprocess(data.known.orig)
data.class <- preprocess(data.class.orig, response = FALSE)

sample.size <- floor(0.75 * nrow(data.known))
sample.training.idx <- sample(nrow(data.known), size = sample.size)

data.preprocessed.train <- data.known[sample.training.idx, ]
data.preprocessed.val <- data.known[-sample.training.idx, ]

# This is awfully slow but unfortunately the only way of package that does what we want
woemodel <- woe(return ~ item_color + user_title + 
                  user_state + item_id + item_size + brand_id, data = data.preprocessed.train, zeroadj=0.5)

# Writing my own applyWoes function because predict does not work in this case for woe scores
applyWoes <- function(data, woemodel) {
  for (var in c("item_color", "user_title", "user_state", "item_id", "item_size", "brand_id")) {
    data[var] <- -as.numeric(woemodel$woe[[var]][data[[var]]])
  }
  return(data)
}

data.known <- applyWoes(data.known, woemodel)
data.class <- applyWoes(data.class, woemodel)

data.preprocessed.train <- data.known[sample.training.idx, ] %>%
  mutate(return = as.numeric(return) - 1)
data.preprocessed.val <- data.known[-sample.training.idx, ] %>%
  mutate(return = as.numeric(return) - 1)

IV <- create_infotables(data=data.preprocessed.train,
                        valid=data.preprocessed.val,
                        y="return")

plot_infotables(IV, IV$Summary$Variable[1:6])
plot_infotables(IV, IV$Summary$Variable[7:12])

summary(data.known)
# Model

#model.formula <- as.formula("return ~ item_price + user_title + user_reg_date + age + days_until_delivery + free_item + user_orders + item_orders + brand_orders")
#model.formula.class <- as.formula("~ item_price + user_title + user_reg_date + age + days_until_delivery + free_item + user_orders + item_orders + brand_orders")
model.formula <- as.formula("return ~ .")
model.formula.class <- as.formula("~ .")

set.seed(123)

# Seperate training and test set
sample.size <- floor(0.75 * nrow(data.known))
sample.training.idx <- sample(nrow(data.known), size = sample.size)
data.training <- data.known[sample.training.idx, ]
data.test <- data.known[-sample.training.idx, ]

### Choosing meta parameters

# Seperate additional validation set


sample.val.size <- floor(0.8 * nrow(data.training))
sample.training.val.idx <- sample(nrow(data.training), size = sample.val.size)
data.training.val <- data.training[sample.training.val.idx,]
data.val <- data.training[-sample.training.val.idx,]

data.training.val.x <- model.matrix(model.formula, data = data.training.val)
data.training.val.y <- data.training.val$return
data.val.x <- model.matrix(model.formula, data = data.val)
data.val.y <- data.val$return

# Randomly shuffle the data
data.training <- data.training[sample(nrow(data.training)),]

crValidCreateFolds <- function(data, k = 5) {
  # Create 5 folds
  folds <- cut(seq(1,nrow(data)),breaks=k,labels=FALSE)
  return(folds)
}

crValidCreateVal <- function(data, folds, k) {
  idx <- which(folds==k, arr.ind=TRUE)
  return(data[-idx, ])
}

crValidCreateTraining <- function(data, folds, k) {
  idx <- which(folds==k, arr.ind=TRUE)
  return(data[idx, ])
}

data.folds <- crValidCreateFolds(data.training, k = 10)

#-----------------
# Cross-validation of lambda for lasso regression
#-----------------

lambdas <- seq(0.001, 0.015, 0.001)

cross.valid.lambda <- function(data, folds, k, lambda) {
  aucs <- vector("double", length = k)
  for (i in 1:k) {
    training.set <- crValidCreateTraining(data, folds, i)
    val.set <- crValidCreateVal(data, folds, i)
    
    training.set.x <- model.matrix(model.formula, data = training.set)
    training.set.y <- training.set$return
    lasso.training.meta <- glmnet(training.set.x, training.set.y, family = "binomial")
    
    val.set.x <- model.matrix(model.formula, data = val.set)
    val.set.y <- val.set$return
    yhat.val.lasso <- predict(lasso.training.meta, newx = val.set.x, s = lambda, type = "response")
    h.val <- HMeasure(val.set.y, yhat.val.lasso)
    aucs[i] = h.val$metrics$AUC
  }
  
  return(aucs)
}

auc.matrix <- matrix(0, ncol = length(lambdas), nrow = 10)

i = 1
for (lambda in lambdas) {
  auc.matrix[,i] <- cross.valid.lambda(data.training, data.folds, 10, lambda)
  i = i + 1
}

colnames(auc.matrix) <- lambdas
df.auc <- data.frame(auc.matrix)
ggplot(data = melt(df.auc), aes(x=variable, y=value)) +
  geom_boxplot(aes(fill=variable))

# Highest AUC at around 0.002

lambda <- 0.002

lasso.training.meta <- glmnet(data.training.val.x, data.training.val.y, family = "binomial")

pred.lasso.test = predict(lasso.training.meta, newx = data.val.x, s = lambda, type = "response")
preds <- data.frame(pred.lasso.test)
names(preds) <- c("lasso")

ggplot() +
  geom_roc(mapping = aes(d = as.numeric(data.val.y) - 1, m = preds$lasso), n.cuts = 10, labelround = 4)

# let's cross-validate thaus from 0.45 thru 0.5

#---------------
# Cross-validation of thau
#---------------

cross.valid.thau <- function(data, folds, k, thau) {
  accs <- vector("double", length = k)
  for (i in 1:k) {
    training.set <- crValidCreateTraining(data, folds, i)
    val.set <- crValidCreateVal(data, folds, i)
    
    training.set.x <- model.matrix(model.formula, data = training.set)
    training.set.y <- training.set$return
    lasso.training.meta <- glmnet(training.set.x, training.set.y, family = "binomial")
    
    val.set.x <- model.matrix(model.formula, data = val.set)
    val.set.y <- val.set$return
    yhat.val.lasso <- predict(lasso.training.meta, newx = val.set.x, s = lambda, type = "response")
    
    predicted.lasso.val <- factor(ifelse(yhat.val.lasso > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
    accs[i] <- sum(predicted.lasso.val == val.set.y) / length(val.set.y)
  }
  
  return(accs)
}

thaus <- seq(0.40, 0.55, 0.01)

acc.matrix <- matrix(0, ncol = length(thaus), nrow = 10)

i = 1
for (thau in thaus) {
  acc.matrix[,i] <- cross.valid.thau(data.training, data.folds, 10, thau)
  i = i + 1
}

colnames(acc.matrix) <- thaus
df.acc <- data.frame(acc.matrix)
ggplot(data = melt(df.acc), aes(x=variable, y=value)) +
  geom_boxplot(aes(fill=variable))

# We observe the highest median accuracy at 0.465, whereas the median accuracy at 0.4675 is slightly
# lower, but the error is lower. I choose a thau of 0.4675.

#---------------
# TODO: Cross-validation of cp and minsize for decision tree
#---------------

cross.validate.dt <- function(data, folds, k, cp, minsplit = 20) {
  aucs <- vector('double', length = k)
  
  for (i in 1:k) {
    training.set <- crValidCreateTraining(data, folds, i)
    val.set <- crValidCreateVal(data, folds, i)
    
    val.set.y <- val.set$return
    
    dt.cross <- rpart(model.formula, data = training.set, method = "class", control = rpart.control(cp = cp, minsplit = minsplit))
    yhat.dt.cross <- predict(dt.cross, newdata = val.set)
    
    h.cross <- HMeasure(as.numeric(val.set.y) - 1, yhat.dt.cross[,2])
    aucs[i] = h.cross$metric$AUC
  }
  
  return(aucs)
}

cp.candidates = c(0.001, 0.005, seq(0.01, 0.1, 0.01))
minsplit.candidates <- c(50, 100, 250, 500, 1000)

# we identify a cp value of 0.001 as the best value
# going further with some minsplit candidates with fixed cp rom here on out

cp.candidates = c(0.001)
minsplit.candidates <- seq(200, 600, 50)

dt.candidates <- expand.grid(cp.candidates, minsplit.candidates)

colnames(dt.candidates) <- c("cp", "minsplit")

auc.matrix.dt <- matrix(0, ncol = nrow(dt.candidates), nrow = 10)
for (i in 1:nrow(dt.candidates)) {
  auc.matrix.dt[,i] <- cross.validate.dt(data.training, data.folds, 10, cp = dt.candidates[i,]$cp, minsplit = dt.candidates[i,]$minsplit)
}

colnames(auc.matrix.dt) <- paste("cp", dt.candidates$cp, "minsplit", dt.candidates$minsplit)
df.auc.dt <- data.frame(auc.matrix.dt)
ggplot(data = melt(df.auc.dt), aes(x=variable, y=value)) +
  geom_boxplot(aes(fill=variable))

# We choose a value for cp of .001 and minsplit of 350

#-----------------------
# Accuracies for decision tree
#-----------------------

cp = 0.001
minsplit = 350

cross.valid.dt.thau <- function(data, folds, k, thau) {
  accs <- vector("double", length = k)
  for (i in 1:k) {
    training.set <- crValidCreateTraining(data, folds, i)
    val.set <- crValidCreateVal(data, folds, i)
    
    training.set.y <- training.set$return
    
    dt.cross <- rpart(model.formula, data = training.set, method = "class", control = rpart.control(cp = cp, minsplit = minsplit))
    yhat.dt.cross <- predict(dt.cross, newdata = val.set)
    
    predicted.lasso.val <- factor(ifelse(yhat.dt.cross[,2] > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
    accs[i] <- sum(predicted.lasso.val == val.set.y) / length(val.set.y)
  }
  
  return(accs)
}

thaus.dt <- seq(0.45, 0.5, 0.0025)

acc.dt.matrix <- matrix(0, ncol = length(thaus.dt), nrow = 10)

i = 1
for (thau in thaus.dt) {
  acc.dt.matrix[,i] <- cross.valid.thau(data.training, data.folds, 10, thau)
  i = i + 1
}

colnames(acc.dt.matrix) <- paste(thaus)
df.dt.acc <- data.frame(acc.dt.matrix)
ggplot(data = melt(df.dt.acc), aes(x=variable, y=value)) +
  geom_boxplot(aes(fill=variable))

# This gives us the same value for thau as in the lasso regression

#-------------------
# Predictions for test set
#-------------------

data.training.x = model.matrix(model.formula, data = data.training)
data.training.y = data.training$return

data.test.x = model.matrix(model.formula, data = data.test)
data.test.y = data.test$return

lasso.training = glmnet(data.training.x, data.training.y, family = "binomial")

lambda <- 0.002
pred.lasso.test = predict(lasso.training, newx = data.test.x, s = lambda, type = "response")
#pred.lr.test = predict(lr.training, newdata = data.test, type = "response")
pred.dt.test = predict(dt.training, newdata = data.test)
preds <- data.frame(pred.lasso.test)#, pred.lr.test)#pred.dt.test[,2])
names(preds) <- c("lasso")#, "lr")#, "dt")

cp = 0.001
minsplit = 250
dt.training = rpart(model.formula, data = data.training, method = "class", control = rpart.control(cp = cp, minsplit = minsplit))

pred.lasso.test = predict(lasso.training, newx = data.test.x, s = lambda, type = "response")
#pred.lr.test = predict(lr.training, newdata = data.test, type = "response")
pred.dt.test = predict(dt.training, newdata = data.test)
preds <- data.frame(pred.lasso.test, pred.dt.test[,2])
names(preds) <- c("lasso", "dt")#, "lr")#, "dt")

thau = 0.5
thau.dt = 0.5
predicted.lasso.test <- factor(ifelse(pred.lasso.test > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
predicted.dt.test <- factor(ifelse(pred.dt.test[,2] > thau.dt, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))

yhats = data.frame(y = as.numeric(data.test.y) - 1, dt = preds$dt, lasso = preds$lasso)

ggplot(data = melt_roc(yhats, "y", c("dt", "lasso"))) +
  geom_roc(mapping = aes(d = D, m = M, color = name), n.cuts = 10, labelround = 4)

ggplot() +
  geom_roc(mapping = aes(d = as.numeric(data.test.y) - 1, m = preds$lasso), n.cuts = 10, labelround = 4)

writeLines("=======================\nLasso regression\n=======================")
print(confusionMatrix(predicted.lasso.test, data.test.y, positive="returned"))

brier <- function(data.true, data.predicted) {
  sum((data.true - data.predicted)^2) / length(data.true)
}

brier.lasso.test <- sum((as.numeric(data.test.y) - 1 - pred.lasso.test)^2) / length(pred.lasso.test)
print(sprintf("Brier score for test set: %f", brier.lasso.test))
h.lasso.test <- HMeasure(as.numeric(data.test.y) - 1, pred.lasso.test)
print(sprintf("AUC for test set: %f", h.lasso.test$metrics$AUC))

writeLines("========================\nMetrics for training set\n========================")

pred.lasso.training = predict(lasso.training, newx = data.training.x, s = lambda, type = "response")
predicted.lasso.training <- factor(ifelse(pred.lasso.training > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
print(confusionMatrix(predicted.lasso.training, data.training.y, positive="returned"))

brier.lasso.training <- sum((as.numeric(data.training.y) - 1 - pred.lasso.training)^2) / length(pred.lasso.training)
print(sprintf("Brier score for training set: %f", brier.lasso.training))
h.lasso.training <- HMeasure(as.numeric(data.training.y) - 1, pred.lasso.training)
print(sprintf("AUC for training set: %f", h.lasso.training$metrics$AUC))

thau = .5
predicted.lr <- factor(ifelse(preds$lasso > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
print(confusionMatrix(predicted.lr, data.test.y, positive="returned"))

thau = 0.58
predicted.dt.test <- factor(ifelse(pred.dt.test[,2] > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))

writeLines("=========================\nDecision tree\n=========================")

print(confusionMatrix(predicted.dt.test, data.test.y, positive="returned"))

brier.dt.test <- sum((as.numeric(data.test.y) - 1 - pred.dt.test[,2])^2) / length(pred.dt.test[,2])
print(sprintf("Brier score for test set: %f", brier.dt.test))
h.dt.test <- HMeasure(as.numeric(data.test.y) - 1, pred.dt.test[,2])
print(sprintf("AUC for test set: %f", h.dt.test$metrics$AUC))

writeLines("========================\nMetrics for training set\n========================")

pred.dt.training = predict(dt.training, newdata = data.training)
predicted.dt.training <- factor(ifelse(pred.dt.training[,2] > thau, 1, 0), levels = c(0, 1), labels = c("not returned", "returned"))
print(confusionMatrix(predicted.dt.training, data.training.y, positive="returned"))

brier.dt.training <- sum((as.numeric(data.training.y) - 1 - pred.dt.training[,2])^2) / length(pred.dt.training[,2])
print(sprintf("Brier score for training set: %f", brier.dt.training))
h.dt.training <- HMeasure(as.numeric(data.training.y) - 1, pred.dt.training[,2])
print(sprintf("AUC for training set: %f", h.dt.training$metrics$AUC))

# We observe roughly the same values for both test and training set, hence our model seems not to be overfitting.

# Prediction

pred.dt.class <- predict(dt.training, newdata = data.class)
predicted.dt.class <- ifelse(pred.dt.class[,2] > thau, 1, 0)
predictions <- data.frame(order_item_id = as.numeric(levels(data.class$order_item_id))[data.class$order_item_id],
                          return = predicted.dt.class)

write.csv(predictions, file = "565429_pien.csv", row.names = FALSE)


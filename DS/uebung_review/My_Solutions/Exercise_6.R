setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")

loans <- GetLoanDataset()
x <- model.matrix(object =  BAD ~ ., data=loans)
y <- loans$BAD

# Train three models
if(!require("rpart")) install.packages("rpart")
if(!require("glmnet")) install.packages("glmnet")
library("glmnet")
library("rpart")
lr <- glm(formula = BAD ~ ., data=loans, family = binomial(link = "logit"))
lasso <- glmnet(x=x, y=y, family="binomial", alpha=1, nlambda=100)
dt <- rpart(BAD~., data = loans, method = "class", control = rpart.control(cp = 0.003, minsplit = 20))

yhat <- list()
yhat[["lr"]] <- predict(object = lr, newdata= loans, type = "response")
yhat[["lasso"]] <- as.vector(predict(object=lasso, newx=x, s = 0.001, type="response"))
yhat[["dt"]] <- predict(object = dt, newdata = loans, type = "prob")[,2]

if(!require("caret")) install.packages("caret")
library("caret")
# convert to discrete predictions
tau <- 0.25
yhat_class <- lapply(yhat, function(placeholder){factor(placeholder > tau, labels=c("good", "bad"))})
confusionMatrix(data = yhat_class[["lr"]], reference = y, positive = "bad")
confusionMatrix(data = yhat_class[["dt"]], reference = y, positive = "bad")

if(!require("hmeasure"))install.packages("hmeassure")
library("hmeasure")

yhat.df <- data.frame(yhat)

h <- HMeasure(yhat.df, true.class = as.numeric(loans$BAD) - 1)
plotROC(h)

h$metrics["AUC"]

# Stratified split
train_idx = createDataPartition(y=loans$BAD, p=0.75, list=FALSE)
X_train = loans[train_idx,]
X_test = loans[-train_idx,]

X_tr <- model.matrix(BAD ~ . -1, data = X_train)
X_ts <- model.matrix(BAD ~ . -1, data = X_test)
y_tr <- X_train$BAD
y_ts <- X_test$BAD

# Retrain lr & dt on new training data
lr <- glm(formula = BAD ~ ., data=X_train, family = binomial(link = "logit"))
lasso <- glmnet(x = X_tr, y = y_tr, family = "binomial", alpha = 1, lambda = 100)
dt <- rpart(formula = BAD ~ ., data = X_train, control = rpart.control(minsplit = 20, cp = 0.003))

yhat <- list()
yhat[["lr"]] <- predict(object = lr, newdata = X_test, type = "response")
yhat[["lasso"]] <- as.vector(predict(object = lasso, newx = X_ts, s = 0.001, type = "response"))
yhat[["dt"]] <- predict(object = dt, newdata = X_test, type="prob")[,2]

# yhat_class <- lapply(yhat, function(x){factor(x > tau, labels=c("good", "bad"))})
yhat.df <- data.frame(yhat)
h <- HMeasure(true.class = as.numeric(X_test$BAD) -1, scores = yhat.df, severity.ratio = 0.1)
auc_splitsampling <- h$metrics["AUC"]
auc_splitsampling
plotROC(h)


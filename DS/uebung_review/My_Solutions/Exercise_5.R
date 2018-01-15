setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")

# Regularization
loans <- GetLoanDataset()
lr <- glm(formula = BAD ~ ., family = binomial(link = "logit"), data=loans)
# summary(lr)
pred.lr <- predict(object = lr, newdata = loans, type = "response")
y <- as.numeric(loans$BAD) - 1

Accuracy <- function(prediction, class, threshold=0.5){
  predClass <- ifelse(prediction < threshold, levels(class)[2], levels(class)[1])
  acc <- sum(predClass == class) / length(class)
  return(acc)
}

class.lr <- ifelse(pred.lr > 0.5, 1, 0)
accuracy <- vector()
accuracy["lr"] <- sum(class.lr == loans$BAD) / length(class.lr)

# Get a benchmark
baseline_probability <- sum(loans$BAD == "bad") / nrow(loans)
class.benchmark <- rep(baseline_probability, nrow(loans))
accuracy["benchmark"] <- Accuracy(prediction = class.benchmark, loans$BAD, threshold=0.5)
class.random <- sample(c(0,1), size= nrow(loans), replace = TRUE, prob = c(1-baseline_probability, baseline_probability))
accuracy["random"] <- Accuracy(prediction = class.random, loans$BAD, threshold = 0.5)


brier.lr <- sum((y - class.lr)^2) / length(y)
brier.base <- sum((y - 0)^2) / length(y)
brier.base

##### GLMNET

if(!require("glmnet")) install.packages("glmnet")
library("glmnet")
x <- model.matrix(object=BAD ~ . -1 , data=loans)
y <- loans$BAD

glm_lr <- glmnet(x = x, y = y, family = "binomial", alpha=1, nlambda = 100)
plot(glm_lr, xvar="lambda")
plot(glm_lr, xvar="dev")

plot(y = glm_lr$dev.ratio, x = glm_lr$lambda)

coef(glm_lr, 0.01)
pred.lasso <-predict(glm_lr, newx = x, s  = 0.01, type="response")
accuracy.lasso <- Accuracy(pred.lasso, class=loans$BAD)

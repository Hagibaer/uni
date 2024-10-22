#Set-up
setwd("C:/Users/Hagen/uni/DS")
source(file = "Rintro_HelperFunctions.R")
loans = GetLoanDataset(file="Loan_Data.csv")

# General logistic regression
lr <- glm(formula = BAD ~ ., data=loans, family=binomial(link='logit')) 
summary(lr)

# Get the significant columns
selector <- summary(lr)$coeff[-1,4] < 0.05
which(selector, arr.ind = TRUE)

# Predict on loans (tasks requires it)
pred.lr <- predict(lr, newdata = loans, type='response')

pred.lr.logit <- ifelse(pred.lr > 0.5, 1,0) #map logit to classes
y <- as.integer(loans$BAD) -1
classification_error <- mean(pred.lr.logit != y)
summary(pred.lr)
print(paste('Accuracy', 1-classification_error))


# Brier score
sum((y-pred.lr)^2) / length(y)


# glmnet library for lasso-regularized logistic regression
library('glmnet')

#better way would be to use input_space <-  model.matrix(Bad-.-1, loans)
target_space <- loans$BAD
input_space <- loans[, !(names(loans) %in% c('BAD'))]
input_space <- data.matrix(input_space)

rlm <-glmnet(x=input_space, y=target_space, family='binomial', standardize=TRUE, alpha=1)
plot(rlm, xvar="lambda", label=TRUE)
summary(rlm)
print(rlm)

#predict
rlm_predict <- predict(rlm, newx=input_space ,type = "response")

"
standardize data
numeric_idx <- sapply(loans, is.numeric)
loans[numeric_idx] <- sapply(loans[numeric_idx], standardize)

target_space <- loans$dINC_A
input_space <- loans[numeric_idx & !(names(loans[numeric_idx]) %in% c('dINC_A'))] 
?glmnet
glmnet(x=input_space, y=target_space, family='gaussian')
"

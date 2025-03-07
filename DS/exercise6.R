#Set-up
setwd("C:/Users/Hagen/uni/DS")
source(file = "Rintro_HelperFunctions.R")
loans <- GetLoanDataset(file="Loan_Data.csv")

# logistic regression
lr <- glm(formula = BAD ~ . -BAD, data=loans, family=binomial(link='logit')) 

# lasso-regularized
library('glmnet')
target_space <- loans$BAD
class(target_space)
input_space <- loans[, !(names(loans) %in% c('BAD'))]
input_space <- data.matrix(input_space)

rlm <-glmnet(x=input_space, y=target_space, family='binomial', standardize=TRUE, alpha=1)
#lambda = 100

# decision tree

library('rpart')
dt <- rpart(BAD ~ . -BAD, data = loans, method = "class",  control=rpart.control(cp=0.003, minsplit=20))

pred.lr <- predict(lr, newdata = loans, type='response')
pred.rlm <- predict(rlm, newx=input_space ,type = "response", s=0.02)
pred.dt <- predict(dt, newdata= loans, type="prob")
#pred.lr.logit <- ifelse(pred.lr > 0.5, 1,0)
#pred.rlm.logit <- ifelse(pred.rlm > 0.5, 1,0)
#pred.dt.logit <- ifelse(pred.dt > 0.5, 1,0)


yhat = data.frame(pred.lr, pred.rlm, pred.dt[,2])
names(yhat) <- c('lr', 'rlm', 'dt')
pred.rlm.logit <- factor(ifelse(yhat$rlm > 0.5, 1, 0), levels=c(0,1), labels=c('good', 'bad'))
pred.dt.logit <- factor(ifelse(yhat$dt > 0.5, 1, 0), levels=c(0,1), labels=c('good', 'bad'))
library('caret')

#install.packages('e1071')
confusionMatrix(pred.rlm.logit, target_space, positive='good')
confusionMatrix(pred.dt.logit, target_space, positive='good')

library('hmeasure')
target_space
ifelse(yhat > 0.5, 1, 0)
target_space <- factor(target_space, levels = c('good', 'bad'), labels = c(0,1))
h = HMeasure(true.class = target_space, scores = yhat)

plotROC(h)


h$metrics$AUC


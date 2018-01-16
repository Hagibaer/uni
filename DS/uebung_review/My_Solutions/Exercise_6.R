setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")

loans <- GetLoanDataset()
x <- model.matrix(object =  BAD ~ ., data=loans)
y <- loans$BAD

# Train three models
lr <- glm(formula = BAD ~ ., data=loans, family = binomial(link = "logit"))
lasso <- glmnet(x=x, y=y, family="binomial", alpha=1, nlambda=100)
dt <- rpart(formula = BAD ~ ., data = loans, cp="auto", method="class", minsplit=20)

yhat <- list()
yhat[["lr"]] <- predict(object = lr, newdata= loans, type = "response")
yhat[["lasso"]] <- as.vector(predict(object=lasso, newx=x, s = 0.001, type="response"))
yhat[["dt"]] <- predict(object = dt, newdata = loans, type = "prob")[,2]


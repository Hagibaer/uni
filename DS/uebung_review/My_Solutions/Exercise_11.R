setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")
if(!require("mlr")) install.packages("mlr")
library("mlr")
loans <- GetLoanDataset()
loans <- mlr::createDummyFeatures(loans)

if(!require("caret")) install.packages("caret")
library("caret")

set.seed(42)
idx.train <- caret::createDataPartition(y = loans$BAD.bad, p=0.8, list=FALSE)
ts <- loans[-idx.train]
tr <- loans[idx.train]

task <- makeClassifTask(data=tr, target="BAD", positive = "bad")

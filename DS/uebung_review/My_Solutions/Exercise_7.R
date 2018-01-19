setwd("C:/Users/hagen/uni/DS/uebung_review/My_Solutions")
#1 Load helperfile
source(file = "../helper/Rintro_HelperFunctions.R")


# Load the data set 
if(!require("nnet")) install.packages("nnet"); library("nnet") # Try to load rpart, if it doesn't exist, then install and load it
if(!require("caret")) install.packages("caret"); library("caret") # Try to load rpart, if it doesn't exist, then install and load it
if(!require("ModelMetrics")) install.packages("ModelMetrics"); library("ModelMetrics") # Try to load rpart, if it doesn't exist, then install and load it
# Link to the R script storing your function(s)
loans <- GetLoanDataset()

train_idx <- createDataPartition(y=loans$BAD, p=0.8, list = FALSE)
tr_raw <- loans[train_idx,]
ts_raw <- loans[-train_idx,]
nnet_raw <- nnet(BAD ~ ., data = X_train, trace=FALSE, maxit=1000, size=3, decay=0.001)


lm <- glm(formula = BAD~.,data = tr_raw, family = binomial(link = "logit"))
yhat <- list()
yhat[["benchmark"]] <- predict(lm, newdata = ts_raw, type="response")
yhat[["nn_raw"]] <- predict(nnet_raw, newdata = ts_raw, type="raw")

h <- hmeasure::HMeasure(true.class= as.numeric(ts_raw$BAD)-1, scores = data.frame(yhat))
h$metrics["AUC"]

#normalizing
normalizer <- caret::preProcess(tr_raw, method=c("center", "scale"))
tr <- predict(normalizer, newdata = tr_raw)
ts <- predict(normalizer, newdata=ts_raw)

nn <- nnet(BAD~., data=tr, trace=FALSE, maxit=1000, size=6, decay=0)
yhat[["nn"]] <- predict(nn, newdata = ts, type="raw")
h <- hmeasure::HMeasure(true.class = as.numeric(ts_raw$BAD)-1, scores = data.frame(yhat) )
h$metrics["AUC"]

# We can do better by using package NeuralNetTools
if(!require("NeuralNetTools")) install.packages("NeuralNetTools"); library("NeuralNetTools")
plotnet(nn, max_sp = TRUE)



library("mlr")
set.seed(42)

# 1. Define a Task: Classification
task <- mlr::makeClassifTask(data=loans, target = "BAD",positive = "bad")

# 2. Define a model: neural net from before
model <- mlr::makeLearner(cl = "classif.nnet", predict.type = "prob", par.vals = list("trace" = FALSE, "maxit" = 1000))

# 3. Prepare tuning
nn.params <- makeParamSet(
  makeNumericParam("decay", lower=-4, upper=0, trafo = function(x) 10^x), # This function thingy makes it from 1*10^-4 to ^0
  makeDiscreteParam("size", values = c(seq(3,15,3)))
)

tuneControl <-  mlr::makeTuneControlGrid(resolution = 4, tune.threshold = FALSE)

# 4. Sampling strategy  - kfolds
rdesc <- makeResampleDesc(method="CV", stratify = TRUE, iters=5)

# 5. Actually tune
tuning <- mlr::tuneParams(learner=model, task=task, resampling = rdesc, measures = mlr::auc, par.set = nn.params, control = tuneControl)
tuning$x

# 6. Evaluation
tuning_summary <- mlr::generateHyperParsEffectData(tuning)
tuning_summary$data

mlr::plotHyperParsEffect(tuning_summary, x="size", y="auc.test.mean")


# 7. Create optimal learner
nnet_tuned <- mlr::setHyperPars(learner = model, par.vals = tuning$x)

# 8. Train opt.learner on complete data-set
model <- mlr::train(nnet_tuned, task=task)

# 9. Predict on test data
pred_raw <-  predict(object = model, newdata = ts)

# 10. Evaluation 
mlr::performance(pred = pred_raw, measures=list(mlr::auc, mlr::brier, mlr::acc))


# Compare
yhat[["nnet_mlr"]] <- pred_raw$data$prob.bad
h <- hmeasure::HMeasure(true.class= as.numeric(ts$BAD) - 1, scores = data.frame(yhat))
h$metrics["AUC"]

hmeasure::plotROC(h)

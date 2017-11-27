# setup
setwd("C:/Users/Hagen/uni/DS")

# Load prepared data
X_train = read.csv(file="Submission_1/data/X_train.csv", header=TRUE, sep=",")
X_test = read.csv(file="Submission_1/data/X_test.csv", header=TRUE, sep=",")
y_train = read.csv(file="Submission_1/data/y_train.csv", header=FALSE, sep=",")

# Convert categorical_columns to factors
for(col in colnames(X_train)){
  if(!startsWith(col, 'X')){
    X_train[[col]] = as.factor(X_train[[col]])
  }
}

for(col in colnames(X_test)){
  if(!startsWith(col, 'X')){
    X_test[[col]] = as.factor(X_test[[col]])
  }
}

# Best model from the set (Logistic_Regression, Decision_Tree, Random_Forest, Bayes) was LR (tested in Python skript)
X_train <- data.matrix(X_train)
X_test <- data.matrix(X_test)
y_train <- as.factor(y_train$V1)



# Train model
library('glmnet')
rlm <-glmnet(x=X_train, y=y_train, family='binomial', standardize=TRUE, alpha=1)


#predict
rlm_predict <- predict(rlm, newx=X_test ,type = "response", s=0.01)
rlm_predict <- ifelse(rlm_predict > 0.5, 1, 0)


# Create a dataframe with two columns: order_item_id = 100001 - 150000 and return = prediction
order_item_id = seq(from=100001, to=150000, by = 1)
return = rlm_predict
return <- sapply(return, function(x) paste0("'", x)) # to outsmart excel



df = data.frame(order_item_id, return)
colnames(df) <- c('order_item_id', 'return')
write.csv(df, '589187_mohr.csv', row.names = FALSE)

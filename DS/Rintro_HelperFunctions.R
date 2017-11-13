######################################################################################
#
#   Library with a set of helper functions for the Tutorial
#
######################################################################################

# Function to load the  loan data set (simple version)
GetLoanDataset <-function(file = "Loan_Data.csv") {
  # Assume the name of the data set is Loan_Data.csv
  data <- read.csv(file, sep = ";")
  # Convert categorical variables into factors
  data$BAD <- factor(data$BAD, labels=c("good", "bad"))
  # replace missing values
  data$YOB[data$YOB == 99] <- NA
  data$YOB_missing <- ifelse(is.na(data$YOB), 1, 0)
  data$YOB[is.na(data$YOB)] <- as.numeric(names(table(data$YOB))[table(data$YOB) == max(table(data$YOB))])
  return(data)
}

# Function to load the churn data set (simple version)
GetChurnDataset <-function() {
  # Assume the name of the data set is Loan_Data.csv
  data <- read.csv("UCI_telecom1_churn.csv", sep = ";", header = TRUE)
  
  # Convert categorical variables to factor
  data$Churn <- factor(data$Churn, labels = c("no", "yes"))
  data$Area.Code <- factor(data$Area.Code, labels = c("X408", "X415", "X510"))
  
  # drop some variables
  data$State <- NULL
  data$Phone <- NULL
  
  return(data)
}

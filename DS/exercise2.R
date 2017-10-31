# set working directory
setwd("C:/Users/Hagen/uni/DS")
# load data from csv
loan <- read.csv('loan_data.csv',sep = ';', header = TRUE)
str(loan)

#summarise data
summary(loan)

# Get caret and look at the train-method (idk why, part of the task)
library(caret)
help(train)

# Histogram time 
hist(loan$dINC_A)  # single value with default function
library(Hmisc)
hist(loan) # All the values with Hmisc

# Boxplot
inc.good <- loan$dINC_A[loan$BAD == 0]
inc.bad <- loan$dINC_A[loan$BAD == 1]

boxplot(x = inc.good, inc.bad, names = c('Good', 'Bad'), ylab=('Applicants income [$]'))


# compare salary means
mean_good = mean(inc.good)
mean_bad = mean(inc.bad)
difference = mean_good - mean_bad
result = t.test(inc.good, inc.bad)
print(result$p.value) # is small and therefore significant yaayy \o/

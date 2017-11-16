# set working directory
setwd("C:/Users/Hagen/uni/DS/Submission_1")

# get the data with class labels
df = read.csv('data/BADS_WS1718_known.csv')

# look if df loaded properly
tail(df)


# check for na's
apply(df, 2, function(x) length(which(!is.na(x))))
# No (!) N/As in any column

# Get the colnames
colnames(df)

# Figure out numeric columns
sapply(df, is.numeric)
# order_item_id, item_id, brand_id, item_price, user_id, return

# Figure out factor columns
sapply(df, is.factor)
# order_date, delivery_date, item_size, item_color, user_title, user_dob, user_state, user_reg_date

# return is not factorized!
df$return <- as.factor(df$return)
df$brand_id <- as.factor(df$brand_id)
df$item_id <- as.factor(df$item_id)

# Look at the numeric values
numeric_idx <- sapply(df, is.numeric)
df[numeric_idx]

#Check their number of disctinct values
lapply(df[numeric_idx], function(x) length(unique(x)))
   
# order_item_id = 100000 --> every order has a different id
# item_id = 2656 --> we have 2656 different items in our observations
# brand_id = 155 --> 155 different brands
# item_price = 332 --> 332 different prices
# user_id = 37663 --> 37663 distinct customers
# Since IDs have no inherent explanatory value for us, we can only check the price for numerical plausability
summary(df$item_price) #Min is at 0.00. A price of 0 is not reasonable
hist(df$item_price)
length(df$item_price[df$item_price<=0]) # 356 of 10.000 samples have a price of 0 (or negative). 3,56% of the samples
length(df$item_price[df$item_price > 400]) # No price is greater than 400€, so there are no outliers in the higher price-segments

t <- df[c('return', 'item_price')]
t$return[t$item_price == 0] # <-- some 0 priced items have been returned

# Moving on to the categorical values
# Looking at the values
factor_idx <- sapply(df, is.factor)

df[factor_idx]$order_date  # seems fine

df[factor_idx]$delivery_date # missing values marked wih '?'

df[factor_idx]$item_size # very mixed, form letters, to numbers to words like 'unsized'
unique(df[factor_idx]$item_size) #114 different sizes, need to cluster them somehow

df[factor_idx]$item_color # seems fine (sadly not, why u betray me item_color?! :-(  )
unique(df[factor_idx]$item_color) #85 values, also '?' outliers

df[factor_idx]$user_title # 'not_reported' outliers
unique(df[factor_idx]$user_title) # 5 categories (Mrs, Mr, not reported, Family, Company)

df[factor_idx]$user_dob # missing values with '?'
unique(df[factor_idx]$user_dob)

df[factor_idx]$user_state # seems fine
unique(df[factor_idx]$user_state) # 16 categories, matches with the number of states in Germany - hooray \o/ 

df[factor_idx]$user_reg_date # seems fine
unique(df[factor_idx]$user_reg_date)

non_numeric_idx <- lapply(df$item_size, is.numeric)


# data-preprocessing
# columns that need work: 
colnames(df)
# 1. delivery-date --> missing values with ?  --> new column (del date known)
# 2. item_size --> 114 categories is to much, needs cleanup (clustering)
# 3. item_color --> missing values
# 4. item_price --> Define how to handle price == 0$
# 5. user_title --> what to do with 'not_reported'. Keep
# 6. user_dob --> calculate age and categorize (young, medium, old, other (for missing values))
# 7. (dont forget to make price a factor)
# 8. Maybe derive more insightful values --> OrderDate-DeliveryDate could be interesting, or count on user_id (how often they ordered alreday)
colnames(df)

table(df$item_color)
sort.int(summary(df$item_color), decreasing = TRUE) # Categorize after most common ones
sort.int(summary(df$user_title), decreasing = TRUE)
sort.int(summary(df$item_id), decreasing = TRUE)
sort.int(summary(df$brand_id), decreasing = TRUE)
sort.int(summary(df$item_size), decreasing = TRUE)

t <- df[c('return', 'user_title')]
summary(t$return[t$user_title == 'Mrs'])


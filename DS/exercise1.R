# Variables and Classes
a <- 3.0
b <- 4.5
class(a)
class(b) == 'character'
a^2 + 1/b
sqrt(a*b)
log2(a)

# Matrix algebra
A = matrix(c(1,4,7,2,5,8,3,6,10), nrow=3)
B = matrix(c(1:9), nrow=3)
y = matrix(c(1:3))

a * A
A %*% B
invA = solve(A)
A %*%invA
t(B)
B[1,] = c(1,1,1)
ols = function(A, y) solve(t(A)%*%A)%*%t(A)%*%y
ols(A, y)


# Indexing
# A B y (anzeigen)
A[3,2] * B[2,1]
A[1,] * B[,3]
y[y>1]
A[,2][A[,1] >= 4]
# A[4,]

# Custom function
standardize = function(x) {
  if (is.numeric(x)){
    mu = mean(x)
    std = sd(x) 
    return((x - mu) / std)
  }
  else{
    return(x)
  }
}

a = c(-100, -25, -10, 0, 10, 25, 100)
standardize(a)

# Using inbuilt-functions
dnorm(x = c(1,2,3,6))
x = seq(-2,2, by=0.2)
nvValues = dnorm(x, mean = 0, sd = 1)
plot(x = x, y = nvValues, type='l')


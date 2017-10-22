A <- matrix(c(1, sqrt(2), sqrt(2), 0),ncol = 2)
eigen(A)

B <- matrix(c(1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1), ncol=4)
B
eigen(B)

C <- matrix(c(0,1,2,1), ncol = 2,byrow = TRUE)
C
C^10
D <- matrix(c(1,2,3,4), ncol = 2, byrow = TRUE)
solve(D)

E <- matrix(c(2, -2, 3, 0 ,3, 1, 2, -8, 1), ncol=3, byrow=TRUE)
solve(E)

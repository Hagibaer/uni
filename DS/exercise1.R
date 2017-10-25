# variables and classes
a = 3.0
b = 4.5
class Class():
    def __init__(self, name):
        self.name = name
        
    def __repr__(self):
        return str(self.name)
print(Class(a))
print(Class(b) == "character")
print(a**2 + 1/b)
import math
print(math.sqrt(a*b))
print(math.log2(a))

# Matrix algebra
import numpy as np

A = np.array([1, 4, 7, 2, 5, 8, 3, 6, 10]).reshape(3, -1)
B = np.arange(1, 10).reshape(3, -1)
y = np.arange(1, 4)

print(a*A)
print(np.dot(A, B))
invA = np.linalg.inv(A)
print(np.dot(A, invA))
print(B.T)
B[1, :] = [1, 1, 1]
print(B)

# Indexing
print(A[2, 1] * B[1, 0])
print(A[0,:] * B[:,2])
print(y[y>1])
print(A[:,1][A[:,0] >= 4])

def standardize(x):
    if isinstance(x ,np.ndarray):
        mu = np.mean(x)
        std = np.std(x)
        return ((x-mu)/std)
    else:
        return x

a = np.array([-100, -25, -10, 0, 10, 25, 100])

standardize(a)
from scipy.stats import norm
norm.pdf([1, 2, 3, 6])
x = np.arange(-2, 2, 0.2)
nvValues = norm.pdf(x, loc=0, scale=1)
from matplotlib import pyplot as plt
import seaborn as sns
sns.set()
plt.plot(x, nvValues)
plt.show()

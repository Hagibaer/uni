import numpy as np

# Sigmoid function to map results between 0-1
def sigmoid(result):
    result = np.exp(result) / (1 + np.exp(result))
    return result

def get_log_likelihood(y_target, beta, input_space):
    # Formel: Sum(yi * Beta * xi - ln(1 + exp(Beta*xi)))
    # TODO: 1-padding? --> No is already in get_coefficients()
    ll = np.sum(y_target * np.dot(input_space, beta) - np.log(1 + np.exp(np.dot(input_space, beta))))
    return ll

def hessian(input_space, beta): 
    # since the hessian matrix for H(Beta) is given as 2nd par. deriv. from l(beta)/dBeta dBeta^T
    # Formula (after deriving): Sum(- (xi^2*e^BetaT*xi) / (1 + e^(BetaT*xi))^2  --> not sure, and since it doesnt work its probably wrong
    # sum (xixiT (h(xi)*(1-h0(xi))))
    # h0(x) = exp(input_space, beta)/ (1+ exp(input_space, beta))
    input_squared = np.dot(input_space.T, input_space)
    h0 = np.exp(np.dot(input_space, beta))
    hessian = np.dot(input_squared, (np.dot(h0, (1-h0))))
    #nomiator = np.dot(input_space.T**2, np.exp(np.dot(input_space, beta))) * -1
    #denomiator = (1 + np.dot(input_space, beta))**2
    #hessian = np.divide(nomiator, denomiator)
    return hessian

def is_invertible(a):
    return a.shape[0] == a.shape[1] and np.linalg.matrix_rank(a) == a.shape[0]

def get_coefficients(input_space, y_target, steps, gamma,  beta_init_multiplier=0, method='gradient'):
    # pad input space with 1
    input_space = np.hstack((np.ones((input_space.shape[0],1)), input_space))
    
    # initialize beta-vector with values
    beta = np.ones(input_space.shape[1])*beta_init_multiplier
    
    for i in range(steps):
        continouus_prediction = np.dot(input_space, beta) # weil Y = XB (B = Beta)
        scaled_prediction = sigmoid(continouus_prediction)
        
        error = y_target - scaled_prediction
        
        gradient =  np.dot(input_space.T, error)
        
        if method == 'gradient':
            beta = beta + gamma * gradient
        elif method == 'newton-raphson':
            hess = hessian(input_space, beta)
            
            """if not is_invertible(hess):
                diagonal_values = np.diagonal(hess, offset=1)
                np.fill_diagonal(hess, diagonal_values)
                hessian_inverse = np.linalg.inv(hess)
            # Implement update rule here -- still not working!
            else:"""
            hessian_inverse = np.linalg.inv(hess)
            beta = beta - np.dot(hessian_inverse, gradient)
        else:
            raise('Please specify a correct update rule for beta')
        
    # print('Log-Likelihood: {}'.format(get_log_likelihood(y_target, beta, input_space)))
    
    return beta
        
def predict(X_test, beta):
    # Check if X_test & beta have right dimensions:
    if not X_test.shape[1] == beta.shape[0] :
        X_test = np.hstack((np.ones((X_test.shape[0],1)), X_test)) # pad test-data
    
    y_predict = np.dot(X_test, beta)
    y_predict = np.round(sigmoid(y_predict))
    return y_predict

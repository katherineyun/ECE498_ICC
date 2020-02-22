"""
2. lossFunction.function : function implementing the loss, (Z - y) ** 2.
   Provide a file lossFunction.py with "function" implemented within it
"""

import tensorflow as tf

def function(a, X, b, Y):
    Z = a*tf.linalg.matmul(tf.transpose(X), X) + tf.linalg.matmul(tf.transpose(b),X)
    loss = (Z-Y)**2
    return loss

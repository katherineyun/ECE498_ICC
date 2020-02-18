"""
1. initializeX.function : function returning the tensorflow variable X initialized to a random value.
   Provide a file initializeX.py with "function" implemented within it
"""

import tensorflow as tf
import numpy as np
#print(tf.__version__)

def function(shape):
    return tf.Variable(tf.random.uniform(shape))
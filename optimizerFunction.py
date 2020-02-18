"""
3. optimizerFunction.function : function implementing the training step
   Provide a file optimizerFunction.py with "function" implemented within it
"""

import tensorflow as tf

def function(loss, lr):
    optimizer = tf.compat.v1.train.AdamOptimizer(lr).minimize(loss)
    return optimizer
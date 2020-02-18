"""
4. computeLoss.function : function that provides a printable value of the loss. By printable, what we mean
   is that the value of loss is visible on using python print(). Using print directly on tensorflow variables
   or constants doesn't show their value.
   Provide a file computeLoss.py with "function" implemented within it
"""

import tensorflow as tf
def function(session, loss):
    return session.run(loss)
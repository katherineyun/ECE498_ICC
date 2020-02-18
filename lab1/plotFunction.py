#
import matplotlib.pyplot as plt

def function(lossValues):
    
    plt.plot(lossValues)
    plt.title('Loss value across trainig steps')
    #plt.xlabel('Iteration')
    plt.ylabel('Loss')
    plt.show()
    return 
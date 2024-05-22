import pandas as pd
from scipy.io import savemat
import numpy as np

def OD_transfer(): # 转化OD的csv文件到mat文件中
    data = pd.read_csv('../data/SiouxFalls/SiouxFalls_od.csv')
    zero_matrix = np.zeros((24, 24))

    for d in data.values:
        zero_matrix[int(d[0])-1, int(d[1])-1] = int(d[2])/100
    savemat('OD.mat', {'od':zero_matrix})
    #print(zero_matrix)

def net_transfer():
    data = pd.read_csv('../data/SiouxFalls/SiouxFalls_net_my.csv')
    zero_matrix1 = [] # capacity
    zero_matrix2 = [] # fft
    zero_matrix3 = np.zeros((24, 24)) # edge
    for d in data.values:
        zero_matrix1.append([int(d[1]), int(d[2]),int(d[3])])
        zero_matrix2.append([int(d[1]), int(d[2]),int(d[4])])
        zero_matrix3[int(d[1]) - 1, int(d[2]) - 1] = 1
    savemat('NET.mat', {'capacity': zero_matrix1, 'fft': zero_matrix2, "edge": zero_matrix3})
net_transfer()
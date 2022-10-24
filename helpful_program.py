#!/usr/bin/python3

from cmath import sqrt
import math
import sys

D = int(sys.argv[1])    # Dimension of the DxD sensor matrix
n = float(sys.argv[2])  # Distance between neighboring sensors
r = float(sys.argv[3])  # Range

with open("topology.txt",'r+') as f:
    f.truncate(0)

for i in range(0, D**2):
    i_long = (i // D) * n
    i_lat = (i % D) * n
    for j in range (0, D**2):
        if i!=j:
            j_long = (j // D) * n
            j_lat = (j % D) * n
            # Euclidean distance
            dist = math.sqrt((i_long-j_long)**2 +(i_lat-j_lat)**2)
            # Check if the distance is in range
            if dist <= r:
                line = str(i)+" "+str(j)+" -50.0"+ "\n"
                with open('topology.txt', 'a') as f:
                    f.write(line)

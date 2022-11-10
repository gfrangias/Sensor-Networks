#!/usr/bin/python3

from cmath import sqrt
import math
import sys

D = int(sys.argv[1])    # Dimension of the DxD sensor matrix
r = float(sys.argv[2])  # Range

with open("topology.txt",'w') as f:
    for i in range(0, D**2):
        i_long = (i // D) 
        i_lat = (i % D)
        for j in range (0, D**2):
            if i!=j:
                j_long = (j // D) 
                j_lat = (j % D)
                # Euclidean distance
                dist = math.sqrt((i_long-j_long)**2 +(i_lat-j_lat)**2)
                # Check if the distance is in range
                if dist <= r:
                    line = str(i)+" "+str(j)+" -50.0"+ "\n"
                    f.write(line)  

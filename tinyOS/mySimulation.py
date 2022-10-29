#!/usr/bin/python

####### Create TOSSIM Object ####### 
from TOSSIM import *
import sys ,os
import random

t=Tossim([])
f=sys.stdout #open('./logfile.txt','w')
####################################

# Compute when the simulation ended
SIM_END_TIME= 1000 * t.ticksPerSecond()

print "TicksPerSecond : ", t.ticksPerSecond(),"\n"

####### Select which debug messages are shown on terminal #######
#t.addChannel("Boot",f)
#t.addChannel("RoutingMsg",f)
#t.addChannel("NotifyParentMsg",f)
#t.addChannel("Radio",f)
#t.addChannel("Serial",f)
t.addChannel("SRTreeC",f)
#t.addChannel("PacketQueueC",f)
#################################################################

####### Start nodes in range, at slightly different moments #######
for i in range(0,10):
	m=t.getNode(i)
	m.bootAtTime(10*t.ticksPerSecond() + i)
###################################################################

# Choose which topology file to open 
topo = open("topology3.txt", "r")

# When topology file can't be found
if topo is None:
	print "Topology file not opened!!! \n"


# Create radio
r=t.radio()
lines = topo.readlines()
# Read topology line-by-line
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    # Add the connection of two sensors to the radio 
    # including the percentage of signal signal strength loss
    r.add(int(s[0]), int(s[1]), float(s[2]))

# Get environment variable
mTosdir = os.getenv("TINYOS_ROOT_DIR")
noiseF=open(mTosdir+"/tos/lib/tossim/noise/meyer-heavy.txt","r")
lines= noiseF.readlines()

for line in lines:
	str1=line.strip()
	if str1:
		val=int(str1)
		for i in range(0,10):
			t.getNode(i).addNoiseTraceReading(val)
noiseF.close()
for i in range(0,10):
	t.getNode(i).createNoiseModel()
	
ok=False
#if(t.getNode(0).isOn()==True):
#	ok=True
h=True

# Run events as long as the simulation is still running
while(h):
	try:
		h=t.runNextEvent()
		#print h
	except:
		print sys.exc_info()
#		e.print_stack_trace()

	if (t.time()>= SIM_END_TIME):
		h=False
	if(h<=0):
		ok=False

# Show if the left node is connected to the right node and the inverse
# These should be either both True or both False
print "Node 0 connected with node 1" , r.connected(0,1) , r.connected(1,0)
print "Node 0 connected with node 2" , r.connected(0,2) , r.connected(2,0)
print "Node 1 connected with node 7" , r.connected(1,7) , r.connected(7,1)
print "Node 2 connected with node 3" , r.connected(2,3) , r.connected(3,2)
print "Node 4 connected with node 8" , r.connected(4,8) , r.connected(8,4)

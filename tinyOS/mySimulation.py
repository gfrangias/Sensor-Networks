#!/usr/bin/python

####### Create TOSSIM Object ####### 
from TOSSIM import *
import sys ,os
import random

t=Tossim([])
f=sys.stdout #open('./logfile.txt','w')
####################################

# Compute when the simulation ended
SIM_END_TIME= 1200 * t.ticksPerSecond()

print "TicksPerSecond : ", t.ticksPerSecond(),"\n"

####### Select which debug messages are shown on terminal #######
#t.addChannel("Boot",f)
#t.addChannel("RoutingMsg",f)
#t.addChannel("NotifyParentMsg",f)
#t.addChannel("Radio",f)
#t.addChannel("Serial",f)
#t.addChannel("SRTreeC",f)
#t.addChannel("PacketQueueC",f)
t.addChannel("TCT",f)
t.addChannel("aggregation_function",f)
t.addChannel("Routing result",f)
t.addChannel("Measures",f)
t.addChannel("Epoch",f)
#t.addChannel("MeasureMsg",f)
#t.addChannel("Random",f)
t.addChannel("Matrix",f)
t.addChannel("Tina",f)
#################################################################

####### Start nodes in range, at slightly different moments #######
for i in range(0,10):
	m=t.getNode(i)
	m.bootAtTime(10*t.ticksPerSecond() + i)
###################################################################

# Choose which topology file to open 
topo = open("topology.txt", "r")

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

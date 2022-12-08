#!/usr/bin/python

from TOSSIM import *
import sys ,os
import random

t=Tossim([])
f=sys.stdout #open('./logfile.txt','w')
SIM_END_TIME= 1200 * t.ticksPerSecond()

print "TicksPerSecond : ", t.ticksPerSecond(),"\n"

#t.addChannel("Boot",f)
t.addChannel("RoutingMsg",f)
#t.addChannel("NotifyParentMsg",f)
#t.addChannel("Radio",f)
#t.addChannel("Serial",f)
#t.addChannel("SRTreeC",f)
#t.addChannel("PacketQueueC",f)
#t.addChannel("TCT",f)
#t.addChannel("aggregation_function",f)
t.addChannel("Routing result",f)
t.addChannel("Measures",f)
t.addChannel("Epoch",f)
#t.addChannel("MeasureMsg",f)
#t.addChannel("Random",f)
t.addChannel("Matrix",f)
t.addChannel("Tina",f)
t.addChannel("Result",f)

for i in range(0,25):
	m=t.getNode(i)
	m.bootAtTime(10*t.ticksPerSecond() + i)


topo = open("topology5.1.50.txt", "r")

if topo is None:
	print "Topology file not opened!!! \n"


	
r=t.radio()
lines = topo.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

mTosdir = os.getenv("TINYOS_ROOT_DIR")
noiseF=open(mTosdir+"/tos/lib/tossim/noise/meyer-heavy.txt","r")
lines= noiseF.readlines()

for line in  lines:
	str1=line.strip()
	if str1:
		val=int(str1)
		for i in range(0,25):
			t.getNode(i).addNoiseTraceReading(val)
noiseF.close()
for i in range(0,25):
	t.getNode(i).createNoiseModel()
	
ok=False
#if(t.getNode(0).isOn()==True):
#	ok=True
h=True
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

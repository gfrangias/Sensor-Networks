#include "SimpleRoutingTree.h"
#include <time.h>
#include <math.h>
#include <stdlib.h>
#ifdef PRINTFDBG_MODE
#include "printf.h"
#endif

module SRTreeC
{
	uses interface Boot;
	uses interface SplitControl as RadioControl;

	uses interface Packet as RoutingPacket;
	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;

	uses interface Packet as MeasurePacket;
	uses interface AMSend as MeasureAMSend;
	uses interface AMPacket as MeasureAMPacket;

	uses interface Timer<TMilli> as RoutingMsgTimer;
	uses interface Timer<TMilli> as StartMeasureTimer;
	uses interface Timer<TMilli> as NewEpochTimer;
	uses interface Timer<TMilli> as EndRoutingTimer;
	
	uses interface Receive as RoutingReceive;
	uses interface Receive as MeasureReceive;
	
	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;

	uses interface PacketQueue as MeasureSendQueue;
	uses interface PacketQueue as MeasureReceiveQueue;

	uses interface Random;
}
implementation
{
	uint16_t  roundCounter;
	uint8_t rand_num;

	message_t radioRoutingSendPkt;
	message_t radioMeasMsgSendPkt;
		
	bool RoutingSendBusy=FALSE;
	bool MeasureSendBusy=FALSE;
	bool MeasureTimerSet=FALSE;
	
	bool lostRoutingSendTask=FALSE;
	bool lostRoutingRecTask=FALSE;
	bool tina_condition=FALSE;

	uint8_t curdepth;
	uint16_t parentID;
	uint8_t tct;
	uint8_t agg_function;
	uint8_t min_val;
	uint8_t max_val;
	uint8_t i;
	uint16_t seed;
	uint8_t last_max;
	uint8_t last_count;
	uint8_t last_tina_max;
	uint8_t last_tina_count;
	uint8_t meas_max;
	uint8_t meas_count;
	
	FILE* f;

	nodeInfo children_values[MAX_CHILDREN];
	
	task void sendRoutingTask();
	task void receiveRoutingTask();

	void setLostRoutingSendTask(bool state)
	{
		atomic{
			lostRoutingSendTask=state;
		}
		if(state==TRUE)
		{

		}
		else 
		{

		}
	}
	
	void setLostRoutingRecTask(bool state)
	{
		atomic{
		lostRoutingRecTask=state;
		}
	}
	void setRoutingSendBusy(bool state)
	{
		atomic{
		RoutingSendBusy=state;
		}
		if(state==TRUE)
		{

		}
		else 
		{

		}
	}

	event void Boot.booted()
	{
		call RadioControl.start();
		
		setRoutingSendBusy(FALSE);
		roundCounter =0;

		//generate seed using urandom from UNIX
		f = fopen("/dev/urandom", "r");
		fread(&seed, sizeof(seed), 1, f);
		fclose(f);
		srand(seed);
		
		if(TOS_NODE_ID==0)
		{
			curdepth=0;
			parentID=0;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
#ifdef PRINTFDBG_MODE
			printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
			printfflush();
#endif
		}
		else
		{
			curdepth=-1;
			parentID=-1;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
#ifdef PRINTFDBG_MODE
			printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
			printfflush();
#endif
		}
	}
	
	event void RadioControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");
#ifdef PRINTFDBG_MODE
			printf("Radio initialized successfully!!!\n");
			printfflush();
#endif
			call EndRoutingTimer.startOneShot(TIMER_ROUTING);
			
			//call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
			//call RoutingMsgTimer.startPeriodic(TIMER_PERIOD_MILLI);
			//call LostTaskTimer.startPeriodic(SEND_CHECK_MILLIS);
			if (TOS_NODE_ID==0)
			{
				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
			}
		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");
#ifdef PRINTFDBG_MODE
			printf("Radio initialization failed! Retrying...\n");
			printfflush();
#endif
			call RadioControl.start();
		}
	}
	
	event void RadioControl.stopDone(error_t err)
	{ 
		dbg("Radio", "Radio stopped!\n");
#ifdef PRINTFDBG_MODE
		printf("Radio stopped!\n");
		printfflush();
#endif
	}

	
	event void RoutingMsgTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;
		
		RoutingMsg* mrpkt;
		dbg("SRTreeC", "RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
#ifdef PRINTFDBG_MODE
		printfflush();
		printf("RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
		printfflush();
#endif
		if (TOS_NODE_ID==0)
		{
			roundCounter+=1;
			
			dbg("Epoch", "##################################### \n");
			dbg("Epoch", "#######   ROUND   %u    ############# \n", roundCounter);
			dbg("Epoch", "#####################################\n");
			//tct = 5*((rand() % 4) + 1);
			tct = 10;
			dbg("TCT", "TCT for round %u is %u\n", roundCounter, tct);
			//agg_function = (rand() % 3);
			agg_function = 0;

			if(agg_function == 0){
				dbg("aggregation_function", "Aggregation function for round %u is MAX\n", roundCounter);
			}else if(agg_function == 1){
				dbg("aggregation_function", "Aggregation function for round %u is COUNT\n", roundCounter);
			}else{
				dbg("aggregation_function", "Aggregation function for round %u is MAX&COUNT\n", roundCounter);
			}
			call NewEpochTimer.startPeriodicAt(-BOOT_TIME, TIMER_PERIOD_MILLI);
			}
		
		if(call RoutingSendQueue.full())
		{
#ifdef PRINTFDBG_MODE
			printf("RoutingSendQueue is FULL!!! \n");
			printfflush();
#endif
			return;
		}
		
		
		mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));
		if(mrpkt==NULL)
		{
			dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");
#ifdef PRINTFDBG_MODE
			printf("RoutingMsgTimer.fired(): No valid payload... \n");
			printfflush();
#endif
			return;
		}
		atomic{
		mrpkt->senderID=TOS_NODE_ID;
		mrpkt->depth = curdepth;
		mrpkt->tct = tct;
		mrpkt->agg_function = agg_function;
		}
		dbg("SRTreeC" , "Sending RoutingMsg... \n");

#ifdef PRINTFDBG_MODE
		printf("NodeID= %d : RoutingMsg sending...!!!! \n", TOS_NODE_ID);
		printfflush();
#endif		
		call RoutingAMPacket.setDestination(&tmp, AM_BROADCAST_ADDR);
		call RoutingPacket.setPayloadLength(&tmp, sizeof(RoutingMsg));
		
		enqueueDone=call RoutingSendQueue.enqueue(tmp);
		
		if( enqueueDone==SUCCESS)
		{
			if (call RoutingSendQueue.size()==1)
			{
				dbg("SRTreeC", "SendTask() posted!!\n");
#ifdef PRINTFDBG_MODE
				printf("SendTask() posted!!\n");
				printfflush();
#endif
				post sendRoutingTask();
			}
			
			dbg("SRTreeC","RoutingMsg enqueued successfully in SendingQueue!!!\n");
#ifdef PRINTFDBG_MODE
			printf("RoutingMsg enqueued successfully in SendingQueue!!!\n");
			printfflush();
#endif
		}
		else
		{
			dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");
#ifdef PRINTFDBG_MODE			
			printf("RoutingMsg failed to be enqueued in SendingQueue!!!\n");
			printfflush();
#endif
		}		
	}
	
	event void NewEpochTimer.fired()
	{
			roundCounter+=1;
			
			dbg("Epoch", "##################################### \n");
			dbg("Epoch", "#######   ROUND   %u    ############# \n", roundCounter);
			dbg("Epoch", "#####################################\n");
	}

	event void RoutingAMSend.sendDone(message_t * msg , error_t err)
	{
		dbg("Routing result", "------Node (%d)----------curdepth = %d , parentID= %d \n", TOS_NODE_ID, curdepth , parentID);
		dbg("SRTreeC", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
		printf("A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
		printfflush();
#endif
		
		dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
#ifdef PRINTFDBG_MODE
		printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
		printfflush();
#endif
		setRoutingSendBusy(FALSE);
		
		if(!(call RoutingSendQueue.empty()))
		{
			post sendRoutingTask();
		}	
		
	}
	
//	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource =call RoutingAMPacket.source(msg);
		
		dbg("SRTreeC", "### RoutingReceive.receive() start ##### \n");
		dbg("SRTreeC", "Something received!!! from %u %u\n",((RoutingMsg*) payload)->senderID , msource);		
		//dbg("SRTreeC", "Something received!!!\n");
		
		//if(len!=sizeof(RoutingMsg))
		//{
			//dbg("SRTreeC","\t\tUnknown message received!!!\n");
//#ifdef PRINTFDBG_MODE
			//printf("\t\t Unknown message received!!!\n");
			//printfflush();
//#endif
			//return msg;
		//}
		
		atomic{
		memcpy(&tmp,msg,sizeof(message_t));
		//tmp=*(message_t*)msg;
		}
		enqueueDone=call RoutingReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS)
		{
#ifdef PRINTFDBG_MODE
			printf("posting receiveRoutingTask()!!!! \n");
			printfflush();
#endif
			post receiveRoutingTask();
		}
		else
		{
			dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
#ifdef PRINTFDBG_MODE
			printf("RoutingMsg enqueue failed!!! \n");
			printfflush();
#endif			
		}
				
		dbg("SRTreeC", "### RoutingReceive.receive() end ##### \n");
		return msg;
	}
	
	////////////// Tasks implementations //////////////////////////////
	
	
	task void sendRoutingTask()
	{
		//uint8_t skip;
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		//message_t radioRoutingSendPkt;
		
#ifdef PRINTFDBG_MODE
		printf("SendRoutingTask(): Starting....\n");
		printfflush();
#endif
		if (call RoutingSendQueue.empty())
		{
			dbg("SRTreeC","sendRoutingTask(): Q is empty!\n");
#ifdef PRINTFDBG_MODE		
			printf("sendRoutingTask():Q is empty!\n");
			printfflush();
#endif
			return;
		}
		
		
		if(RoutingSendBusy)
		{
			dbg("SRTreeC","sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
#ifdef PRINTFDBG_MODE
			printf(	"sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
			printfflush();
#endif
			setLostRoutingSendTask(TRUE);
			return;
		}
		
		radioRoutingSendPkt = call RoutingSendQueue.dequeue();
		
		mlen= call RoutingPacket.payloadLength(&radioRoutingSendPkt);
		mdest=call RoutingAMPacket.destination(&radioRoutingSendPkt);
		if(mlen!=sizeof(RoutingMsg))
		{
			dbg("SRTreeC","\t\tsendRoutingTask(): Unknown message!!!\n");
#ifdef PRINTFDBG_MODE
			printf("\t\tsendRoutingTask(): Unknown message!!!!\n");
			printfflush();
#endif
			return;
		}
		sendDone=call RoutingAMSend.send(mdest,&radioRoutingSendPkt,mlen);
		
		if ( sendDone== SUCCESS)
		{
			dbg("SRTreeC","sendRoutingTask(): Send returned success!!!\n");
#ifdef PRINTFDBG_MODE
			printf("sendRoutingTask(): Send returned success!!!\n");
			printfflush();
#endif
			setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","send failed!!!\n");
#ifdef PRINTFDBG_MODE
			printf("SendRoutingTask(): send failed!!!\n");
#endif
			//setRoutingSendBusy(FALSE);
		}
	}
	/**
	 * dequeues a message and sends it
	 */
	////////////////////////////////////////////////////////////////////
	//*****************************************************************/
	///////////////////////////////////////////////////////////////////
	/**
	 * dequeues a message and processes it
	 */
	
	task void receiveRoutingTask()
	{
		message_t tmp;
		uint8_t len;
		message_t radioRoutingRecPkt;
		
#ifdef PRINTFDBG_MODE
		printf("ReceiveRoutingTask():received msg...\n");
		printfflush();
#endif
		radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();
		
		len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);
		
		dbg("SRTreeC","ReceiveRoutingTask(): len=%u \n",len);
#ifdef PRINTFDBG_MODE
		printf("ReceiveRoutingTask(): len=%u!\n",len);
		printfflush();
#endif
		// processing of radioRecPkt
		
		// pos tha xexorizo ta 2 diaforetika minimata???
				
		if(len == sizeof(RoutingMsg))
		{
			RoutingMsg * mpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));
			
			dbg("SRTreeC" , "receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);
#ifdef PRINTFDBG_MODE
			printf("NodeID= %d , RoutingMsg received! \n",TOS_NODE_ID);
			printf("receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);
			printfflush();
#endif		
			tct = mpkt->tct;
			agg_function = mpkt->agg_function;
			if ( (parentID<0)||(parentID>=65535))
			{
				// tote den exei akoma patera
				parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;q
				curdepth= mpkt->depth + 1;
#ifdef PRINTFDBG_MODE
				printf("NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
				printfflush();
#endif

				if (TOS_NODE_ID!=0)
				{
					call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
				}
			}
			else
			{
				
				if (( curdepth > mpkt->depth +1) || (mpkt->senderID==parentID))
				{
					uint16_t oldparentID = parentID;
					
				
					parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;
					curdepth = mpkt->depth + 1;
				
#ifdef PRINTFDBG_MODE
					printf("NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
					printfflush();
#endif					
									
					if (TOS_NODE_ID!=0)
					{
						call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
					}
				}
								
			}
		}
		else
		{
			dbg("SRTreeC","receiveRoutingTask():Empty message!!! \n");
#ifdef PRINTFDBG_MODE
			printf("receiveRoutingTask():Empty message!!! \n");
			printfflush();
#endif
			setLostRoutingRecTask(TRUE);
			return;
		}
	}

	event void EndRoutingTimer.fired(){

		if(!MeasureTimerSet){
			rand_num = rand() % 240;
		
		dbg("Random", "Node: %d, Random: %d \n", TOS_NODE_ID, rand_num);
		call StartMeasureTimer.startPeriodicAt(-BOOT_TIME-((curdepth+1)*TIMER_VERY_FAST_PERIOD+rand_num),TIMER_PERIOD_MILLI);
		//dbg("Measures", "Timer will wait for: %d \n", TIMER_PERIOD_MILLI-((curdepth+1)*TIMER_VERY_FAST_PERIOD));
		MeasureTimerSet = TRUE;
		}
	}


	// Send one measurement
	task void sendMeasMsg()
	{
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;

		if (call MeasureSendQueue.empty())
		{
			dbg("MeasureMsg","sendMeasMsg(): Q is empty!\n");
			return;
		}
		
		
		if(MeasureSendBusy)
		{
			dbg("MeasureMsg","sendMeasMsg(): MeasureSendBusy= TRUE!!!\n");
			return;
		}
		
		radioMeasMsgSendPkt = call MeasureSendQueue.dequeue();
		
		mlen=call MeasurePacket.payloadLength(&radioMeasMsgSendPkt);
		mdest=call MeasureAMPacket.destination(&radioMeasMsgSendPkt);
		if(mlen!=sizeof(OneMeasMsg))
		{
			dbg("MeasureMsg","\t\\sendMeasMsg(): Unknown message!!!\n");
			return;
		}
		sendDone=call MeasureAMSend.send(mdest,&radioMeasMsgSendPkt,mlen);
		
		if ( sendDone== SUCCESS)
		{
			dbg("MeasureMsg","sendMeasMsg(): Send returned success!!!\n");
			//setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("MeasureMsg","send failed!!!\n");
		}

	}

	// Receive one measurement
	task void receiveMeasMsg()
	{
		message_t tmp;
		uint8_t len;
		message_t radioMeasMsgRecPkt;

		radioMeasMsgRecPkt= call MeasureReceiveQueue.dequeue();
		
		len= call MeasurePacket.payloadLength(&radioMeasMsgRecPkt);
		
		dbg("MeasureMsg","receiveMeasMsg(): len=%u \n",len);

		// processing of radioRecPkt
		
		// pos tha xexorizo ta 2 diaforetika minimata???
				
		if(len == sizeof(OneMeasMsg))
		{
			OneMeasMsg * mpkt = (OneMeasMsg*) (call MeasurePacket.getPayload(&radioMeasMsgRecPkt,len));
			
			//dbg("MeasureMsg" , "receiveMeasMsg():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);
			//dbg("TCT", "receiveMeasMsg():TCT=%d, senderID=%d \n", mpkt->tct, mpkt->senderID);

			// Aggregation etc...
			for(i = 0; i<MAX_CHILDREN; i++)
			{
				if(children_values[i].nodeID == mpkt->senderID || children_values[i].nodeID == 0)
				{
					children_values[i].nodeID = mpkt->senderID;

					if(agg_function == 0)
						children_values[i].max = mpkt->measurement;
					if(agg_function == 1)
						children_values[i].count = mpkt->measurement;

					break;
				}
			}
		}
		else
		{
			dbg("MeasureMsg","receiveMeasMsg():Empty message!!! \n");
			return;
		}
	}

	event void MeasureAMSend.sendDone(message_t * msg , error_t err)
	{
		if(!(call MeasureSendQueue.empty()))
		{
			post sendMeasMsg();
		}
	}

	event message_t* MeasureReceive.receive( message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource = call MeasureAMPacket.source(msg);
		
		dbg("MeasureMsg", "### MeasureReceive.receive() start ##### \n");
		dbg("MeasureMsg", "Something received!!! from %u %u\n",((OneMeasMsg*) payload)->senderID , msource);	

		atomic{
			memcpy(&tmp,msg,sizeof(message_t));
			//tmp=*(message_t*)msg;
		}
		enqueueDone=call MeasureReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
			post receiveMeasMsg();
		}
		else
		{
			dbg("MeasureMsg","MeasureMsg enqueue failed!!! \n");
		}
				
		dbg("MeasureMsg", "### MeasureReceive.receive() end ##### \n");
		dbg("Tina", "Received from %d\n", ((OneMeasMsg*) payload)->senderID);
		return msg;
	}
	
	// Create new measurement values / Compute the aggregation functions
	// Validate based on TiNA / Call send tasks
	event void StartMeasureTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;
		OneMeasMsg* ommpkt;
		TwoMeasMsg* tmmpkt;		

		//dbg("Measures", "Timer FIRED...\n");

		//agg_function = MAX
		if(agg_function == 0)
		{
			// If it's the first epoch and there is no measurement
			if(meas_max==0){
				//dbg("Measures", "Measurement was 0 \n");
				meas_max = (rand() % 80) + 1;
			// If a new measurement is needed
			}else{
				//dbg("Measures", "Old Measurement: %d\n", meas);
				if((meas_max / 10)>0){
					min_val = meas_max - (meas_max / 10);
					max_val = meas_max + (meas_max / 10);
					meas_max =  min_val + (rand() % (max_val-min_val));
				}
			}

			dbg("Measures", "Measurement of node in depth %d before aggregation: %d\n", curdepth, meas_max);

			last_max = meas_max;
			//Loop through children and find MAX
			for(i=0; i<MAX_CHILDREN; i++)
			{
				if(children_values[i].nodeID == 0)
					break;

				if(meas_max<children_values[i].max)
					last_max = children_values[i].max;	
			}
			dbg("Measures", "Measurement in depth %d after aggregation without Tina: %d\n", curdepth, last_max);
		}
		//agg_function = COUNT
		else if(agg_function == 1) 
		{	
			last_count = 1;
			//Calculate COUNT
			for(i=0; i<MAX_CHILDREN; i++)
			{
				if(children_values[i].nodeID == 0)
					break;

				last_count += children_values[i].count;	
			}

			dbg("Measures", "Measurement in depth %d after aggregation without Tina: %d\n", curdepth, last_count);
		}
		else
			exit(0);


		if(agg_function == 0)
		{
			uint8_t meas_diff = 0;

			if(last_tina_max != 0)
				meas_diff = (abs(last_tina_max - last_max)*100)/last_tina_max;

			//dbg("Tina", "Diff: %d\n", meas_diff);

			if(meas_diff > tct || last_tina_max == 0)
			{
				tina_condition = TRUE;
				dbg("Tina", "Tina PASS, Last MAX: %d New MAX: %d\n", last_tina_max, last_max);
				last_tina_max = last_max;
			}
			else
				tina_condition = FALSE;
		}
		else if(agg_function == 1)
		{
			uint8_t meas_diff = 0;
			
			if(last_tina_count != 0)
				meas_diff = (abs(last_tina_count - last_count)*100)/last_tina_count;

			if(meas_diff > tct || last_tina_count == 0)
			{
				tina_condition = TRUE;
				dbg("Tina", "Tina PASS, Last COUNT: %d New COUNT: %d\n", last_tina_count, last_count);
				last_tina_count = last_count;
			}
			else
				tina_condition = FALSE;
		}
		else
			exit(0);


		if(call MeasureSendQueue.full())
		{
			return;
		}
		
		if(tina_condition && TOS_NODE_ID != 0)
		{
			ommpkt = (OneMeasMsg*) (call MeasurePacket.getPayload(&tmp, sizeof(OneMeasMsg)));
			if(ommpkt==NULL)
			{
				dbg("MeasureMsg","StartMeasureTimer.fired(): No valid payload... \n");
				return;
			}
			if(agg_function == 0)
			{
				atomic{
				ommpkt->senderID=TOS_NODE_ID;
				ommpkt->measurement=last_tina_max;
				}
				dbg("Tina", "Sending Measurement to parent %d: %d\n", parentID, last_tina_max);
			}
			else if(agg_function == 1)
			{
				atomic{
				ommpkt->senderID=TOS_NODE_ID;
				ommpkt->measurement=last_tina_count;
				}
				dbg("Tina", "Sending Measurement to parent %d: %d\n", parentID, last_tina_count);
			}
			else
				exit(0);

			dbg("MeasureMsg" , "Sending MeasureMsg... \n");
		
			call MeasureAMPacket.setDestination(&tmp, parentID);
			call MeasurePacket.setPayloadLength(&tmp, sizeof(OneMeasMsg));
			
			enqueueDone=call MeasureSendQueue.enqueue(tmp);

			for(i=0;i<MAX_CHILDREN;i++)
			{
				if(children_values[i].nodeID !=0)
					dbg("Matrix", "Children values: %d %d %d\n", children_values[i].nodeID, children_values[i].max, children_values[i].count);
			}
			
			if( enqueueDone==SUCCESS)
			{
				if (call MeasureSendQueue.size()==1)
				{
					dbg("MeasureMsg", "SendTask() posted!!\n");
					post sendMeasMsg();
				}
				
				dbg("MeasureMsg","MeasMsg enqueued successfully in MeasureSendQueue!!!\n");

			}	
		}
		else if(TOS_NODE_ID == 0)
		{
			if(agg_function == 0)
				dbg("Tina", "Result of aggregation: %d\n", last_tina_max);
			else if(agg_function == 1)
				dbg("Tina", "Result of aggregation: %d\n", last_tina_count);
			else
				exit(0);
		}

	}

}

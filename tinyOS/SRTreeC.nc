#include "SimpleRoutingTree.h"
#include <time.h>
#include <math.h>
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

	uint8_t curdepth;
	uint16_t parentID;
	uint8_t tct;
	uint8_t agg_function;
	uint8_t meas;
	uint8_t min_val;
	uint8_t max_val;

	//children_values nodeInfo[MAX_CHILDREN];
	
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
			tct = 5*((rand() % 4) + 1);
			dbg("TCT", "TCT for round %u is %u\n", roundCounter, tct);
			agg_function = (rand() % 3);

			if(agg_function == 0){
				dbg("AGGREGATION_FUNCTION", "Aggregation function for round %u is MAX\n", roundCounter);
			}else if(agg_function == 1){
				dbg("AGGREGATION_FUNCTION", "Aggregation function for round %u is COUNT\n", roundCounter);
			}else{
				dbg("AGGREGATION_FUNCTION", "Aggregation function for round %u is MAX&COUNT\n", roundCounter);
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
			dbg("TCT", "receiveRoutingTask():TCT=%d, senderID=%d \n", mpkt->tct, mpkt->senderID);
			if(mpkt->agg_function == 0){
				dbg("AGGREGATION_FUNCTION", "receiveRoutingTask():Aggregation fuction=MAX, senderID=%d \n", mpkt->senderID);
			}else if(mpkt->agg_function == 1){
				dbg("AGGREGATION_FUNCTION", "receiveRoutingTask():Aggregation fuction=COUNT, senderID=%d \n", mpkt->senderID);
			}else{
				dbg("AGGREGATION_FUNCTION", "receiveRoutingTask():Aggregation fuction=MAX&COUNT, senderID=%d \n", mpkt->senderID);
			}
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
	
	if(!MeasureTimerSet){
		srand ( TOS_NODE_ID + time(0) );
		rand_num = rand() % 120;
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

		// If it's the first epoch and there is no measurement
		if(meas==0){
			//dbg("Measures", "Measurement was 0 \n");
			srand ( time(0) + TOS_NODE_ID);
			meas = (rand() % 80) + 1;
			//dbg("Measures", "Measurement in depth %d: %d\n", curdepth, meas);

		// If a new measurement is needed
		}else{
			//dbg("Measures", "Old Measurement: %d\n", meas);
			if((meas / 10)>0){
				min_val = meas - (meas / 10);
				max_val = meas + (meas / 10);
				srand ( time(0) );
				meas =  min_val + (rand() % (max_val-min_val));
			}
		}		

		dbg("Measures", "Measurement in depth %d: %d\n", curdepth, meas);


		if(call MeasureSendQueue.full())
		{
			return;
		}
		
		
		ommpkt = (OneMeasMsg*) (call MeasurePacket.getPayload(&tmp, sizeof(OneMeasMsg)));
		if(ommpkt==NULL)
		{
			dbg("MeasureMsg","StartMeasureTimer.fired(): No valid payload... \n");
			return;
		}
		atomic{
		ommpkt->senderID=TOS_NODE_ID;
		ommpkt->measurement=meas;
		}
		dbg("MeasureMsg" , "Sending MeasureMsg... \n");
	
		call MeasureAMPacket.setDestination(&tmp, parentID);
		call MeasurePacket.setPayloadLength(&tmp, sizeof(OneMeasMsg));
		
		enqueueDone=call MeasureSendQueue.enqueue(tmp);
		
		if( enqueueDone==SUCCESS)
		{
			if (call MeasureSendQueue.size()==1)
			{
				dbg("MeasureMsg", "SendTask() posted!!\n");
				post sendMeasMsg();
			}
			
			dbg("MeasureMsg","MeasMsg enqueued successfully in MeasureSendQueue!!!\n");

		}
		else
		{

		}		

	}

}

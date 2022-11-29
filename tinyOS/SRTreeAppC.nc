#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif
	components MainC, ActiveMessageC;
	components new TimerMilliC() as RoutingMsgTimerC;
	components new TimerMilliC() as StartMeasureTimerC;
	components new TimerMilliC() as NewEpochTimer;

	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;

	components new AMSenderC(AM_ROUTINGMSG) as MeasureSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as MeasureReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MeasureSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MeasureReceiveQueueC;
	
	SRTreeC.Boot->MainC.Boot;
	
	SRTreeC.RadioControl -> ActiveMessageC;

	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
	SRTreeC.StartMeasureTimer->StartMeasureTimerC;
	SRTreeC.NewEpochTimer->NewEpochTimer;
	
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;

	SRTreeC.MeasurePacket->MeasureSenderC.Packet;
	SRTreeC.MeasureAMPacket->MeasureSenderC.AMPacket;
	SRTreeC.MeasureAMSend->MeasureSenderC.AMSend;
	SRTreeC.MeasureReceive->MeasureReceiverC.Receive;

	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;

	SRTreeC.MeasureSendQueue->MeasureSendQueueC;
	SRTreeC.MeasureReceiveQueue->MeasureReceiveQueueC;	
}

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
	//components new TimerMilliC() as EndRoutingTimerC;
	components new TimerMilliC() as NewAggTimerC;

	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;

	components new AMSenderC(AM_MEASMSG) as MeasureSenderC;
	components new AMReceiverC(AM_MEASMSG) as MeasureReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MeasureSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MeasureReceiveQueueC;

	components new AMSenderC(AM_AGGMSG) as AggregationSenderC;
	components new AMReceiverC(AM_AGGMSG) as AggregationReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as AggregationSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as AggregationReceiveQueueC;
	
	SRTreeC.Boot->MainC.Boot;
	
	SRTreeC.RadioControl -> ActiveMessageC;

	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
	SRTreeC.StartMeasureTimer->StartMeasureTimerC;
	SRTreeC.NewEpochTimer->NewEpochTimer;
	//SRTreeC.EndRoutingTimer->EndRoutingTimerC;
	SRTreeC.NewAggTimer->NewAggTimerC;
	
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;

	SRTreeC.MeasurePacket->MeasureSenderC.Packet;
	SRTreeC.MeasureAMPacket->MeasureSenderC.AMPacket;
	SRTreeC.MeasureAMSend->MeasureSenderC.AMSend;
	SRTreeC.MeasureReceive->MeasureReceiverC.Receive;

	SRTreeC.AggregationPacket->AggregationSenderC.Packet;
	SRTreeC.AggregationAMPacket->AggregationSenderC.AMPacket;
	SRTreeC.AggregationAMSend->AggregationSenderC.AMSend;
	SRTreeC.AggregationReceive->AggregationReceiverC.Receive;

	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;

	SRTreeC.MeasureSendQueue->MeasureSendQueueC;
	SRTreeC.MeasureReceiveQueue->MeasureReceiveQueueC;	

	SRTreeC.AggregationSendQueue->AggregationSendQueueC;
	SRTreeC.AggregationReceiveQueue->AggregationReceiveQueueC;	
}

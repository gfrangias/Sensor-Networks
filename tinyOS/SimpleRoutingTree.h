#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=40,
	AM_ROUTINGMSG=40,
	AM_NOTIFYPARENTMSG=12,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=30720, 	// Epoch
	TIMER_FAST_PERIOD=200,
	TIMER_VERY_FAST_PERIOD=100,	// Measurement window
	TIMER_LEDS_MILLI=1000,
	TIMER_ROUTING=1024, 
	MAX_CHILDREN=20,
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/
typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;
	nx_uint8_t tct;
	nx_uint8_t agg_function;
} RoutingMsg;

typedef nx_struct NotifyParentMsg
{
	nx_uint16_t senderID;
	nx_uint16_t parentID;
	nx_uint8_t depth;
} NotifyParentMsg;

typedef nx_struct OneMeasMsg
{	
	nx_uint16_t senderID;
	nx_uint16_t parentID;
	nx_uint8_t measurement;
	nx_uint8_t function;
}OneMeasMsg;

typedef nx_struct TwoMeasMsg
{
	nx_uint16_t senderID;
	nx_uint16_t parentID;
	nx_uint8_t measurement1;
	nx_uint8_t measurement2;
}TwoMeasMsg;

typedef struct nodeInfo{
	nx_uint16_t nodeID
}nodeInfo;

#endif

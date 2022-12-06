#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=32,
	AM_ROUTINGMSG=32,
	AM_ONEMEASMSG=24,
	AM_TWOMEASMSG=32,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=30*1024, 	// Epoch
	TIMER_FAST_PERIOD=200,
	TIMER_VERY_FAST_PERIOD=350,	// Measurement window
	TIMER_ROUTING=3*1024, 
	MAX_CHILDREN=10,
	BOOT_TIME=10240,
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/
typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;
	nx_uint8_t parameters;
} RoutingMsg;

typedef nx_struct OneMeasMsg
{	
	nx_uint16_t senderID;
	nx_uint8_t measurement; // Here in the last bits is a flag for the agg. function
}OneMeasMsg;

typedef nx_struct TwoMeasMsg
{
	nx_uint16_t senderID;
	nx_uint8_t max;
	nx_uint8_t count;
}TwoMeasMsg;

typedef struct nodeInfo{
	nx_uint16_t nodeID;
	nx_uint8_t max;
	nx_uint8_t count;
}nodeInfo;

#endif

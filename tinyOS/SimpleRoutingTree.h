#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=17,
	AM_ROUTINGMSG=17,
	AM_ONEMEASMSG=8,
	AM_TWOMEASMSG=16,
	AM_AGGMSG=9,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=30*1024, 	// Epoch
	TIMER_FAST_PERIOD=200,
	TIMER_VERY_FAST_PERIOD=350,	// Measurement window
	TIMER_ROUTING=4*1024, 
	MAX_CHILDREN=10,
	BOOT_TIME=10240,
};
typedef nx_struct RoutingMsg
{
	nx_uint8_t depth;
	nx_uint8_t parameters;
} RoutingMsg;

typedef nx_struct OneMeasMsg
{	
	nx_uint8_t measurement; // Here in the MSB is a flag for the agg. function
}OneMeasMsg;

typedef nx_struct TwoMeasMsg
{
	nx_uint8_t max;
	nx_uint8_t count;
}TwoMeasMsg;

typedef struct nodeInfo
{
	nx_uint16_t nodeID;
	nx_uint8_t max;
	nx_uint8_t count;
}nodeInfo;

typedef struct AggMessage
{
	nx_uint8_t agg_msg;
}AggMessage;

#endif

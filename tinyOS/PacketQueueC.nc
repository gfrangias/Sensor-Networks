
#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

generic module PacketQueueC( uint8_t queueSize)
{
	provides interface PacketQueue;
}
implementation
{
	message_t Q[queueSize];
	uint8_t headIndex=0;
	uint8_t tailIndex=0;
	uint8_t size=0;
	
	//bool isEmpty=TRUE;
	//bool isFull=FALSE;
	
	/**
	* Check if queue is empty
	*/
	command bool PacketQueue.empty()
	{
		bool em;
		atomic{
		em = (size==0);}
		
		return em;
	}
	
	/**
	* Check if queue is full
	*/
	command bool PacketQueue.full()
	{
		bool em;
		atomic{
		if (size==queueSize)
		{
			em=TRUE;
		}
		else
		{
			em=FALSE;
		}
		}
		return em ;
	}

	/**
	* Get the number of packets in the queues
	*/
	command uint8_t PacketQueue.size()
	{
		uint8_t ms;
		
		atomic{
			ms= size;
		}
		return ms;
	}
	
	/**
	* Get the size of the queue
	*/
	command uint8_t PacketQueue.maxSize()
	{
		uint8_t ms;
		
		atomic{
			ms= queueSize;
		}
		return ms;
	}
	
	/**
	 * @deprecated
	 */
	command message_t PacketQueue.head()
	{	
		return Q[headIndex];
	}
	
	
	/**
	* Add a new packet to the queue
	*/
	command error_t PacketQueue.enqueue(message_t newPkt)
	{
		bool wasEmpty=FALSE, isFull=FALSE;
		
		atomic{
		// If size is 0 then the queue was empty
		wasEmpty= (size==0);//call PacketQueue.empty();
		// If size is equal to the queue size the queue is full
		isFull=(size==queueSize);
		}
		
		// If the queue is full
		if (isFull)
		{
			// Print that the queue is full
			dbg("PacketQueueC","enqueue(): Queue is FULL!!!\n");
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC:enqueue(): Queue is FULL!!!\n");
			printfflush();
#endif
			return FAIL;
		}
			// If the queue isn't empty
		atomic{
			if(!wasEmpty)
			{
				// Move tail index one position to the right
				// (Actually create space for the  new packet)
				tailIndex = (tailIndex+1)%queueSize;
			}
			
			// Paste the new packet at the end of the queue
			memcpy(&Q[tailIndex],&newPkt,sizeof(message_t));//???  
			//Q[tailIndex]=*(message_t*)newPkt;
			size++;
		}
		// Print to give update on enqueue
		dbg("PacketQueueC","enqueue(): Enqueued in pos= %u \n",tailIndex);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : enqueue() : pos=%u \n", tailIndex);
		printfflush();
#endif
		return SUCCESS;
	}
	
	/**
	* Remove a packet from the queue
	*/
	command message_t PacketQueue.dequeue()
	{
		uint8_t tmp;
		bool isEmpty=FALSE;
		message_t  m;
		// If size is 0 the queue is empty 
		atomic{
			isEmpty=(size==0);
		}
		// If the queue is empty
		if (isEmpty)
		{
			// Print that the queue is empty
			dbg("PacketQueueC","dequeue(): Q is emtpy!!!!\n");
#ifdef PRINTFDBG_MODE
			printf("PacketQueueC : dequeue() : Q is empty!!! \n");
			printfflush();
#endif
			atomic{
				m=Q[headIndex];
			}
			return m; // must return something to indicate error... (event???)
		}
		
		
		atomic{
			tmp=headIndex;
			// If queue tail and head are different
			if(tailIndex!=headIndex)
			{
				// Move head index one position to the right
				// (Actually delete the packet that is on the head)
				headIndex=(headIndex+1)%queueSize;//???
			}
			// Number of packets in queue decrease by one
			size--;
			// The message m contains the packet that was deleted
			m=Q[tmp];
		}
		// Print to give update on dequeue
		dbg("PacketQueueC","dequeue(): Dequeued from pos = %u \n",tmp);//(queueSize+headIndex-1)%queueSize);
#ifdef PRINTFDBG_MODE
		printf("PacketQueueC : dequeue(): pos = %u \n", tmp);
		printfflush();
#endif
		return m;
	}
	
	/**
	* Read a packet from the queue given its index
	*/
	command message_t PacketQueue.element(uint8_t mindex)
	{
		message_t m;
		atomic{
			m = Q[mindex];
		}
		return m;
	}	
}

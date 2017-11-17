#ifndef DMA_TESTER_H
#define DMA_TESTER_H
#include "dmacontroller.h"
using namespace std;

class DMATester
{
	private:
		DMAController** _controllers;
		char* _writeBuffer;
		char* _readBuffer;
		void fillRandom(char * buf, size_t size);	
	public:
		DMATester();
		~DMATester();
		void TestTransferSize();
		void TestConcurrency();
};

#endif

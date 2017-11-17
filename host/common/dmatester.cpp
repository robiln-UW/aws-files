#include <chrono>
#include <iostream>
#include <stdexcept>
#include <cstring>
#include "dmatester.h"
#include "dmacontroller.h"
#include "stopwatch.h"
#include "math_helper.hpp"
using namespace std;

const size_t BUFFER_SIZE = 1ULL<<34; 
const int MAX_THREAD = 16;
const int NUM_TRIAL = 10;

/*
 * constructor.
 */
DMATester::DMATester()
{
	_controllers = new DMAController*[MAX_THREAD];
	_writeBuffer  = 0;
	_readBuffer = 0;
}

/*
 * destructor.
 */
DMATester::~DMATester()
{
	delete _controllers;
}

/*
 * test latency with varying transfer load size.
 */
void DMATester::TestTransferSize()
{
	cout << "testing transfer size...\r\n";
	auto stopwatch = new Stopwatch();
	_controllers[0] = new DMAController();
	_controllers[0]->init(0);
	
	double writeLatency[NUM_TRIAL];
	double readLatency[NUM_TRIAL];

	for (int i = 0; i < 35; i++)
	{
		size_t buf_size = 1ULL<<i;

		// read/ write buffer
		_writeBuffer = (char*) malloc(buf_size);
		_readBuffer = (char*) malloc(buf_size);
		
		// random buffer for write
		fillRandom(_writeBuffer, buf_size);

		for (int j = 0; j < NUM_TRIAL; j++)
		{
			char seq = (char) (j + 33);
			fillRandom(&seq, 1);
			// write
			stopwatch->start();
			_controllers[0]->write(_writeBuffer, buf_size, 0, 0);
			writeLatency[j] = stopwatch->stop();
			// read
			stopwatch->start();
			_controllers[0]->read(_readBuffer, buf_size, 0, 0);	
			readLatency[j] = stopwatch->stop();
			
			if (memcmp(_writeBuffer, _readBuffer, buf_size) != 0)
			{
				throw runtime_error("memcmp() != 0");
			}			
		}

		cout << "write,"
			<< buf_size << ","
			<< MathHelper::average(writeLatency, NUM_TRIAL) << ","
			<< MathHelper::stdev(writeLatency, NUM_TRIAL) << endl; 
	
		cout << "read,"
			<< buf_size << ","
			<< MathHelper::average(readLatency, NUM_TRIAL) << ","
			<< MathHelper::stdev(readLatency, NUM_TRIAL) << endl; 

		free(_writeBuffer);
		free(_readBuffer);
	}
	cout << "========== end ===========\r\n";
	delete stopwatch;
	delete _controllers[0];
}

/*
 * test latency on varying number of threads transferring block of data.
 */
void DMATester::TestConcurrency()
{
		
}

/*
 * fill buffer with random bytes.
 */
void DMATester::fillRandom(char * buf, size_t size)
{
	srand(time(0));
	for (size_t i = 0; i < size; i++)
	{
		buf[i] = (char) (rand() % 94) + 33;
	}
}





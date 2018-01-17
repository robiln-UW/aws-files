/**
 * 	Stopwatch utility.
 *
 *	@author Tommy Jung
 *	@version 1.0
 */

#include <chrono>
#include <stdexcept>
#include "stopwatch.h"
using namespace std;
using namespace std::chrono;


/*
 *	default constructor.
 */
Stopwatch::Stopwatch()
{
	_started = false;
}

/*
 * 	start the stopwatch.
 */
void Stopwatch::start()
{
	if (_started)
	{
		throw runtime_error("Stopwatch has already started.");
	}
	_started = true;
	_start = high_resolution_clock::now();
}

/*
 * 	stop the stopwatch and return the duration.
 * 	@return amount of time elapsed in seconds.
 */
double Stopwatch::stop()
{
	if (!_started)
	{
		throw runtime_error("Stopwatch has not started.");		
	}

	duration<double> diff = high_resolution_clock::now() - _start;
	_started = false;	
	return diff.count(); 
}

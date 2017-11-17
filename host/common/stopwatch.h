#ifndef STOPWATCH_H
#define STOPWATCH_H

#include <chrono>
using namespace std;
using namespace std::chrono;

class Stopwatch
{
	private:
		bool _started;
		system_clock::time_point _start;
	public:
		Stopwatch();
		void start();
		double stop();		
};

#endif

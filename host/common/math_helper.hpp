#ifndef MATH_HELPER_H
#define MATH_HELPER_H

#include <cstdint>
using namespace std;

class MathHelper
{
	public:
		static double average(double lst[], int size);
		static double variance(double lst[], int size);
		static double stdev(double lst[], int size);
		
		static double average(uint32_t lst[], int size);
		static double variance(uint32_t lst[], int size);
		static double stdev(uint32_t lst[], int size);

};

#endif

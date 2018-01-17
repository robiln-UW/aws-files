/**
 *	math_helper.cpp
 *
 *	@author Tommy Jung
 */

#include <cstdint>
#include <cmath>
#include "math_helper.hpp"
using namespace std;

double MathHelper::average(double lst[], int size)
{
	double acc = 0;
	for (int i = 0; i < size; i++)
	{
		acc += lst[i];
	}

	return acc/size;
}

double MathHelper::variance(double lst[], int size)
{
	double average = MathHelper::average(lst, size);
	double acc = 0;
	for (int i = 0; i < size; i++)
	{
		acc += (lst[i] - average) * (lst[i] - average);
	} 
	return acc/(size-1);
}

double MathHelper::stdev(double lst[], int size)
{
	return sqrt(MathHelper::variance(lst, size));
}

double MathHelper::average(uint32_t lst[], int size)
{
	double acc = 0;
	for (int i = 0; i < size; i++)
	{
		acc += double(lst[i]);
	}

	return acc/size;
}

double MathHelper::variance(uint32_t lst[], int size)
{
	double average = MathHelper::average(lst, size);
	double acc = 0;
	for (int i = 0; i < size; i++)
	{
		acc += (double(lst[i]) - average) * (double(lst[i]) - average);
	} 
	return acc/(size-1);
}

double MathHelper::stdev(uint32_t lst[], int size)
{
	return sqrt(MathHelper::variance(lst, size));
}


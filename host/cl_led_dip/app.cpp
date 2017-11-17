#include <iostream>
#include "dmatester.h"
using namespace std;

int main(int argc, char ** argv)
{		
	auto dmaTester = new DMATester();

	try
	{
		dmaTester->TestTransferSize();
		dmaTester->TestConcurrency();
	}
	catch(exception& e)
	{
		cout << e.what() << endl;			
	}

	delete dmaTester;

	return 0;
}

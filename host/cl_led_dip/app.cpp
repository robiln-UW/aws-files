#include <iostream>
#include "fabricmanager.h"
#include "fpga_mgmt.h"
using namespace std;

int main(int argc, char ** argv)
{		
	auto fabricManager = new FabricManager();
	fpga_mgmt_image_info_t* info = 0;

	try
	{
		// get fpga image info.
		info = fabricManager->getImageInfo(0);
		cout << "FPGA Image Info:" << endl;
		printf("Vendor ID: 0x%x\r\n", info->spec.map[FPGA_APP_PF].vendor_id);
		printf("Device ID: 0x%x\r\n", info->spec.map[FPGA_APP_PF].device_id);


		// set virtual DIP to 0x0000
		fabricManager->setvDIP(0, 0x0000);
		cout << "setting vDIP to 0x0000" << endl;

		// read virtual LED value
		uint16_t vLED = fabricManager->getvLED(0);
		printf("vLED = 0x%x\r\n", vLED);

		// set virtual DIP to 0x0005
		fabricManager->setvDIP(0, 0x0005);
		cout << "setting vDIP to 0x0005" << endl;

		// read virtual LED value
		uint16_t vLED = fabricManager->getvLED(0);
		printf("vLED = 0x%x\r\n", vLED);

		// set virtual DIP to 0x0010
		fabricManager->setvDIP(0, 0x0010);
		cout << "setting vDIP to 0x0010" << endl;

		// read virtual LED value
		vLED = fabricManager->getvLED(0);
		printf("vLED = 0x%x\r\n", vLED);
	}
	catch(exception& e)
	{
		cout << e.what() << endl;			
	}

	// make sure to free dynamically allocated memory.
	free(info);
	delete fabricManager;

	return 0;
}

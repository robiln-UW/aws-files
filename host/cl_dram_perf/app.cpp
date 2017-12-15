/**
 *	Host application for cl_dram_perf	
 *
 *	@author Tommy Jung
 *	@version 1.0
 */

#include <iostream>
#include "fabricmanager.h"
#include "pcihandler.h"
#include "dmacontroller.h"
#include "fpga_mgmt.h"
using namespace std;

#define START_ADDR_REG_ADDR 0x500
#define BURST_LEN_REG_ADDR 0x504
#define WRITE_VAL_REG_ADDR 0x508

const int SLOT_ID = 0;

int main(int argc, char ** argv)
{		
	auto fabricManager = new FabricManager();
	auto pciHandler = new PCIHandler();
	auto dmaController = new DMAController();
	fpga_mgmt_image_info_t* info = 0;

	try
	{
		// get fpga image info.
		info = fabricManager->getImageInfo(SLOT_ID);
		cout << "FPGA Image Info:" << endl;
		printf("Vendor ID: 0x%x\r\n", info->spec.map[FPGA_APP_PF].vendor_id);
		printf("Device ID: 0x%x\r\n", info->spec.map[FPGA_APP_PF].device_id);

		// attach pciHandler.
		pciHandler->attach(SLOT_ID, FPGA_APP_PF, APP_PF_BAR0);

		// init dmaController.
		dmaController->init(SLOT_ID);

		int buf_size = 64*4;
		char * buffer1 = (char *) malloc(sizeof(char) * buf_size);
		char * buffer2 = (char *) malloc(sizeof(char) * buf_size);

		for (int i = 0; i < buf_size; i++)
		{
			buffer1[i] = (char) (97 + (i % 26));	
		}
	
		dmaController->write(buffer1, buf_size, 0, 0);
		dmaController->read(buffer2, buf_size, 0, 0);		

		for (int i = 0; i < buf_size; i++)
		{
			if (buffer1[i] == buffer2[i])
			{
				printf("data matched. addr: %d, buf1: %c, buf2: %c\r\n",
					i, buffer1[i], buffer2[i]);
			}
			else
			{
				printf("data not matched. addr: %d, buf1: %c, buf2: %c\r\n",
					i, buffer1[i], buffer2[i]);
			}
		}

	}
	catch(exception& e)
	{
		cout << e.what() << endl;			
	}

	// make sure to free dynamically allocated memory.
	free(info);
	delete fabricManager;
	delete pciHandler;
	delete dmaController;


	return 0;
}

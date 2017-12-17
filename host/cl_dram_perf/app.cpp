/**
 *	Host application for cl_dram_perf	
 *
 *	@author Tommy Jung
 *	@version 1.0
 */

#include <iostream>
#include <cstdlib>
#include <chrono>
#include <thread>
#include "fabricmanager.h"
#include "pcihandler.h"
#include "dmacontroller.h"
#include "fpga_mgmt.h"
#include "stopwatch.h"
using namespace std;
using namespace std::this_thread;
using namespace std::chrono;

#define START_ADDR_REG_ADDR 0x500
#define BURST_LEN_REG_ADDR 0x504
#define WRITE_VAL_REG_ADDR 0x508

const int SLOT_ID = 0;

int main(int argc, char ** argv)
{		
	auto fabricManager = new FabricManager();
	auto pciHandler = new PCIHandler();
	auto dmaController = new DMAController();
	auto stopwatch = new Stopwatch();
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

		/*
		// init CL memory with random char.
		size_t buf_size = 1 << 30;
		char * buf1 = (char *) malloc(sizeof(char) * buf_size);
		char * buf2 = (char *) malloc(sizeof(char) * buf_size);
		
		for (int i = 0; i < 16; i++)
		{
			for (int j = 0; j < buf_size; j++)
			{
				buf1[j] = (char) (97 + (rand() % 26));	
			}
	
			dmaController->write(buf1, buf_size, 0, buf_size * i);
			dmaController->read(buf2, buf_size, 0, buf_size * i);
		
			bool match = true;
			for (int j = 0; j < buf_size; j++)
			{
				if (buf1[j] != buf2[j])
				{
					match = false;
					printf("data mismatch. i: %d, addr: %x, buf1: %c, buf2: %c\r\n",
						i, j, buf1[j], buf2[j]);
				}
			}

			if (match) 
			{
				printf("DMA write success. i: %d\r\n", i);
			}
			else
			{
				printf("DMA write failed. i: %d\r\n", i);
			}
		}
	
		free(buf1);
		free(buf2);
		*/
		// set start_addr
		pciHandler->poke(START_ADDR_REG_ADDR, 0);
		uint32_t start_addr = pciHandler->peek(START_ADDR_REG_ADDR);
		printf("start_addr = %d\r\n", start_addr);

		// read and write using mem_ctrl
		uint32_t burst_len = 1;
		for (int i = 0; i < 29; i++)
		{
			// set burst_len
			pciHandler->poke(BURST_LEN_REG_ADDR, burst_len-1);
			uint32_t burst_len_read = pciHandler->peek(BURST_LEN_REG_ADDR);
			//printf("burst_len = %d\r\n", burst_len);
			
			// set write_val
			uint32_t write_val = 0;
			for (int j = 0; j < 8; j++)
			{
				write_val = (write_val << 8) + (i % 16);
			}
			
			pciHandler->poke(WRITE_VAL_REG_ADDR, write_val);
			uint32_t write_val_read = pciHandler->peek(WRITE_VAL_REG_ADDR);
			//printf("write_val = 0x%x\r\n", write_val_read);

			// mem_ctrl write
			stopwatch->start();
			fabricManager->setvDIP(SLOT_ID, 0x0002);
			uint16_t vled_read = 0x0000;
			do {
				vled_read = fabricManager->getvLED(SLOT_ID);
				sleep_for(milliseconds(5));
			} while (vled_read != 0x0002);
			double write_latency = stopwatch->stop();	
			printf("write,%d,%f\r\n", burst_len, write_latency);
			fabricManager->setvDIP(SLOT_ID, 0x0000);
			/*
			// validate write		
			char * buf3 = (char *) malloc(sizeof(char)*64*burst_len);
			dmaController->read(buf3, 64 * burst_len, 0, 0);
			bool write_valid = true;
			for (int j = 0; j < 64 * burst_len; j++)
			{
				if (buf3[j] != (i % 16))
				{
					printf("data mismatch. j: %d, buf3: %x, expected: %x\r\n", j, buf3[j], i % 16);
					write_valid = false;
				}
			}

			if (!write_valid)
			{
				printf("mem_ctrl write failed. j: %d\r\n", burst_len);
			}
	
			free(buf3);
			*/

			/*
			// mem_ctrl read
			stopwatch->start();
			fabricManager->setvDIP(SLOT_ID, 0x0001);
			vled_read = 0x0000;

			do {
				vled_read = fabricManager->getvLED(SLOT_ID);
				sleep_for(milliseconds(5));
			} while (vled_read != 0x0001);
			double read_latency = stopwatch->stop();
			printf("read,%d,%f\r\n", burst_len, read_latency);
			fabricManager->setvDIP(SLOT_ID, 0x0000);
			*/
			burst_len *= 2;
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

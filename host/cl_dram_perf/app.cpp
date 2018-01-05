/**
 *	Host application for cl_dram_perf	
 *
 *	@author Tommy Jung
 */

#include <iostream>
#include <cstdlib>
#include <chrono>
#include <thread>
#include <stdexcept>
#include "fabricmanager.h"
#include "pcihandler.h"
#include "dmacontroller.h"
#include "fpga_mgmt.h"
#include "stopwatch.h"
#include "math_helper.hpp"
using namespace std;
using namespace std::this_thread;
using namespace std::chrono;

#define START_ADDR_REG_ADDR 0x500
#define BURST_LEN_REG_ADDR 0x504
#define WRITE_VAL_REG_ADDR 0x508
#define RHASH_REG_ADDR 0x50c
#define RW_EN_REG_ADDR 0x510
#define RW_DONE_REG_ADDR 0x514
#define RD_CLK_COUNT_REG_ADDR 0x518
#define WR_CLK_COUNT_REG_ADDR 0x51c
#define BUF_SIZE (1ULL << 34)

const int SLOT_ID = 0;
const int NUM_TRIAL = 10;
const int BYTE_PER_BURST = 64;

int main(int argc, char ** argv)
{		
	auto fabricManager = new FabricManager();
	auto pciHandler = new PCIHandler();
	auto dmaController = new DMAController();
	auto stopwatch = new Stopwatch();
	fpga_mgmt_image_info_t* info = 0;
	
	char * buf1 = (char *) malloc(sizeof(char) * BUF_SIZE);
	char * buf2 = (char *) malloc(sizeof(char) * BUF_SIZE);

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

		// set start_addr
		pciHandler->poke(START_ADDR_REG_ADDR, 0);
		uint32_t start_addr_read = pciHandler->peek(START_ADDR_REG_ADDR);
		if (start_addr_read != 0)
		{
			throw runtime_error("failed to write start_addr\r\n");
		}

		// measure vdip, vled latency
		double vdip_latency[NUM_TRIAL*10] = {0};
		double vled_latency[NUM_TRIAL*10] = {0};
		for (int i = 0; i < NUM_TRIAL*10; i++)
		{
			stopwatch->start();
			fabricManager->setvDIP(SLOT_ID, 0);
			vdip_latency[i] = stopwatch->stop();
			
			stopwatch->start();
			fabricManager->getvLED(SLOT_ID);
			vled_latency[i] = stopwatch->stop();
		}
	
		double vdip_latency_avg = MathHelper::average(vdip_latency, NUM_TRIAL*10);
		double vdip_latency_stdev = MathHelper::stdev(vdip_latency, NUM_TRIAL*10);
		double vled_latency_avg = MathHelper::average(vled_latency, NUM_TRIAL*10);
		double vled_latency_stdev = MathHelper::stdev(vled_latency, NUM_TRIAL*10);

		printf("[vdip latency] average: %f, stdev: %f\r\n", vdip_latency_avg, vdip_latency_stdev);	
		printf("[vled latency] average: %f, stdev: %f\r\n", vled_latency_avg, vled_latency_stdev);	
	
		// measure AXI-lite latency
		double axi_lite_poke_latency[NUM_TRIAL*10] = {0};
		double axi_lite_peek_latency[NUM_TRIAL*10] = {0};
		for (int i = 0; i < NUM_TRIAL * 10; i++)
		{
			stopwatch->start();
			pciHandler->poke(START_ADDR_REG_ADDR, 0);
			axi_lite_poke_latency[i] = stopwatch->stop();

			stopwatch->start();
			pciHandler->peek(START_ADDR_REG_ADDR);
			axi_lite_peek_latency[i] = stopwatch->stop();
		}

		double axi_lite_poke_latency_avg = MathHelper::average(axi_lite_poke_latency, NUM_TRIAL*10);
		double axi_lite_poke_latency_stdev = MathHelper::stdev(axi_lite_poke_latency, NUM_TRIAL*10);
		double axi_lite_peek_latency_avg = MathHelper::average(axi_lite_peek_latency, NUM_TRIAL*10);
		double axi_lite_peek_latency_stdev = MathHelper::stdev(axi_lite_peek_latency, NUM_TRIAL*10);
		
		printf("[AXI-LITE poke latency] average: %f ms, stdev: %f ms\r\n",
			axi_lite_poke_latency_avg * 1000,
			axi_lite_poke_latency_stdev * 1000);
		printf("[AXI-LITE peek latency] average: %f ms, stdev: %f ms\r\n",
			axi_lite_peek_latency_avg * 1000,
			axi_lite_peek_latency_stdev * 1000);

		// real test
		uint32_t ocl_read = 0;	
		size_t burst_len = 1;
		for (int i = 0; i < 29; i++)
		{
			// set burst_len
			pciHandler->poke(BURST_LEN_REG_ADDR, burst_len-1);
			uint32_t burst_len_read = pciHandler->peek(BURST_LEN_REG_ADDR);
			if (burst_len-1 != burst_len_read)
			{
				throw runtime_error("failed to write burst_len.\r\n");
			}

			double dma_read_latency[NUM_TRIAL] = {0};
			double dma_write_latency[NUM_TRIAL] = {0};
			double cl_read_latency[NUM_TRIAL] = {0};
			double cl_write_latency[NUM_TRIAL] = {0};
			uint32_t cl_read_clk_count[NUM_TRIAL] = {0};
			uint32_t cl_write_clk_count[NUM_TRIAL] = {0}; 

			for (int j = 0; j < NUM_TRIAL; j++)
			{
				// init random char buffer
				for (size_t k = 0; k < burst_len*BYTE_PER_BURST; k++)
				{
					buf1[k] = (char) (97 + (rand() % 26));
				}
				
				// DMA write
				stopwatch->start();
				dmaController->write(buf1, burst_len*BYTE_PER_BURST, 0, 0);
				dma_write_latency[j] = stopwatch->stop();

				// calculate hash
				char rhash1[4] = {0x00,0x00,0x00,0x00};
				for (size_t k = 0; k < burst_len*BYTE_PER_BURST/4; k++)
				{
					rhash1[0] = rhash1[0] ^ buf1[4*k];
					rhash1[1] = rhash1[1] ^ buf1[4*k+1];
					rhash1[2] = rhash1[2] ^ buf1[4*k+2];
					rhash1[3] = rhash1[3] ^ buf1[4*k+3];
				}
				int rhash_expected = 0;
				for (int k = 0; k < 4; k++)
				{
					rhash_expected = (rhash_expected << 8) + rhash1[3-k];
				}

				// CL read
				ocl_read = 0;
				stopwatch->start();
				pciHandler->poke(RW_EN_REG_ADDR, 1);

				do {
					ocl_read = pciHandler->peek(RW_DONE_REG_ADDR);
				} while (ocl_read != 1);						

				cl_read_latency[j] = stopwatch->stop();
				pciHandler->poke(RW_EN_REG_ADDR, 0); // deassert read enable

				uint32_t rhash_actual = pciHandler->peek(RHASH_REG_ADDR);  
				if (rhash_expected != rhash_actual)
				{
					printf("[rhash] expected: %x, actual: %x\r\n", rhash_expected, rhash_actual);
				}
				
				cl_read_clk_count[j] = pciHandler->peek(RD_CLK_COUNT_REG_ADDR);

				// set write_val
				uint32_t write_val = 0;
				for (int k = 0; k < 8; k++)
				{
					write_val = (write_val << 8) + (j % 16);
				}	
			
				pciHandler->poke(WRITE_VAL_REG_ADDR, write_val);
				uint32_t write_val_read = pciHandler->peek(WRITE_VAL_REG_ADDR);
				if (write_val_read != write_val)
				{
					throw runtime_error("failed to set write_val.\r\n");
				}			

				// CL write
				ocl_read = 0;
				stopwatch->start();
				pciHandler->poke(RW_EN_REG_ADDR, 2);

				do {
					ocl_read = pciHandler->peek(RW_DONE_REG_ADDR);
				} while (ocl_read != 2);

				cl_write_latency[j] = stopwatch->stop();
				
				cl_write_clk_count[j] = pciHandler->peek(WR_CLK_COUNT_REG_ADDR);

				pciHandler->poke(RW_EN_REG_ADDR, 0); // deassert write enable

				// DMA read
				stopwatch->start();
				dmaController->read(buf2, burst_len*BYTE_PER_BURST, 0, 0);	
				dma_read_latency[j] = stopwatch->stop();
				
				bool valid = true;
				for (size_t k = 0; k < burst_len*BYTE_PER_BURST; k++)
				{
					if (buf2[k] != (j % 16))
					{
						valid = false;
					}
				}
				
				if (!valid)
				{
					printf("dma data mismatch,\r\n");
				}
			}

			double dma_read_avg = MathHelper::average(dma_read_latency, NUM_TRIAL);
			double dma_read_stdev = MathHelper::stdev(dma_read_latency, NUM_TRIAL);
			double dma_write_avg = MathHelper::average(dma_write_latency, NUM_TRIAL);
			double dma_write_stdev = MathHelper::stdev(dma_write_latency, NUM_TRIAL);
				
			double cl_read_avg = MathHelper::average(cl_read_latency, NUM_TRIAL);
			double cl_read_stdev = MathHelper::stdev(cl_read_latency, NUM_TRIAL);
			double cl_write_avg = MathHelper::average(cl_write_latency, NUM_TRIAL);
			double cl_write_stdev = MathHelper::stdev(cl_write_latency, NUM_TRIAL);
			
			double cl_read_clk_count_avg = MathHelper::average(cl_read_clk_count, NUM_TRIAL);
			double cl_read_clk_count_stdev = MathHelper::stdev(cl_read_clk_count, NUM_TRIAL);
			
			double cl_write_clk_count_avg = MathHelper::average(cl_write_clk_count, NUM_TRIAL);
			double cl_write_clk_count_stdev = MathHelper::stdev(cl_write_clk_count, NUM_TRIAL);
	
			printf("dma,read,%lu,%f,%f\r\n", burst_len, dma_read_avg*1000, dma_read_stdev*1000);
			printf("dma,write,%lu,%f,%f\r\n", burst_len, dma_write_avg*1000, dma_write_stdev*1000);
			printf("cl,read,%lu,%f,%f,%f,%f\r\n", burst_len, cl_read_avg*1000, cl_read_stdev*1000,
				cl_read_clk_count_avg, cl_read_clk_count_stdev);
			printf("cl,write,%lu,%f,%f,%f,%f\r\n", burst_len, cl_write_avg*1000, cl_write_stdev*1000,
				cl_write_clk_count_avg, cl_write_clk_count_stdev);

			burst_len *= 2;
		}

	}
	catch(exception& e)
	{
		cout << e.what() << endl;			
	}

	// make sure to free dynamically allocated memory.
	free(info);
	free(buf1);
	free(buf2);
	delete fabricManager;
	delete pciHandler;
	delete dmaController;
	delete stopwatch;

	return 0;
}

#ifndef FABRIC_MANAGER_H
#define FABRIC_MANAGER_H

#include <cstdint>
using namespace std;

typedef struct fpga_mgmt_image_info fpga_mgmt_image_info_t;

/*
 * Fabric Manager.
 */
class FabricManager
{
	public:
		FabricManager();
		~FabricManager();
		void init();
		fpga_mgmt_image_info_t* getImageInfo(int slot_id);
		void setvDIP(int slot_id, uint16_t value);
		uint16_t getvLED(int slot_id);
};

#endif

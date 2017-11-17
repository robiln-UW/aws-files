#include <stdio.h>
#include <iostream>
#include <string>
#include <stdexcept>

#include <fpga_mgmt.h>

#include "fabricmanager.h"
using namespace std;

// constructor
FabricManager::FabricManager()
{

}

// destructor
FabricManager::~FabricManager()
{

}

// initialize
void FabricManager::init()
{
	int rc = fpga_mgmt_init();
	if (rc)
	{
		throw runtime_error("fpga_mgmt_init() failed. error code: " + to_string(rc) + "\r\n");
	}
}

// Get AFI image info in slot.
fpga_mgmt_image_info_t*  FabricManager::getImageInfo(int slot_id)
{
	fpga_mgmt_image_info_t* info = (fpga_mgmt_image_info_t*) malloc(sizeof(fpga_mgmt_image_info_t));	
	int rc = fpga_mgmt_describe_local_image(slot_id, info, 0);
	if (rc)
	{	
		throw runtime_error("fpga_mgmt_describe_local_image() failed. error code: " + to_string(rc) + "\r\n");
	}

	return info;
}

// set virtual DIP.
void FabricManager::setvDIP(int slot_id, uint16_t value)
{
	int rc = fpga_mgmt_set_vDIP(slot_id, value);
	if (rc)
	{
		throw runtime_error("fpga_mgmt_set_vDIP() failed. error code: " + to_string(rc) + "\r\n");
	}
}


// get virtual LED.
uint16_t FabricManager::getvLED(int slot_id)
{
	uint16_t value;
	int rc = fpga_mgmt_get_vLED_status(slot_id, &value);
	if (rc)
	{
		throw runtime_error("fpga_mgmt_get_vLED_status() failed. error code: " + to_string(rc) + "\r\n");
	}

	return value;	
}





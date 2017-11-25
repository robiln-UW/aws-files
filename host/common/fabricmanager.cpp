/**
 *	FabricManager handles PCIe calls related to Management PF. 
 *  Refer to fpga_mgmt.h in aws-fpga/sdk/userspace/include.
 *
 *	@author Tommy Jung
 *	@version 1.0
 */

#include <stdio.h>
#include <iostream>
#include <string>
#include <stdexcept>
#include <fpga_mgmt.h>
#include "fabricmanager.h"
using namespace std;

/**
 * 	default constructor.
 */
FabricManager::FabricManager()
{

}

/**
 *	destructor.
 */
FabricManager::~FabricManager()
{

}

/**
 *	Initialize fpga_mgmt handle. This function needs to be called first before calling other functions.
 */
void FabricManager::init()
{
	int rc = fpga_mgmt_init();
	if (rc)
	{
		throw runtime_error("fpga_mgmt_init() failed. error code: " + to_string(rc) + "\r\n");
	}
}

/**
 * 	Return the image info of FPGA.
 *	@param slot_id the slot id of the FPGA you want the image info of.
 */
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

/**
 *	Set virtual DIP with the given value.
 *	@param slot_id the slot id of the FPGA to set vDIP.
 *	@param value the value to which to set vDIP.
 */
void FabricManager::setvDIP(int slot_id, uint16_t value)
{
	int rc = fpga_mgmt_set_vDIP(slot_id, value);
	if (rc)
	{
		throw runtime_error("fpga_mgmt_set_vDIP() failed. error code: " + to_string(rc) + "\r\n");
	}
}


/**
 *	Get virtual LED value.
 *  @param slot_id the slot id of the FPGA to get vLED.
 */
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





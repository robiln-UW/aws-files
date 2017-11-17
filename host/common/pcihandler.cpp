#include <stdexcept>
#include <string>
#include <fpga_pci.h>
#include "pcihandler.h"
using namespace std;

/*
 *	default constructor.
 */
PCIHandler::PCIHandler()
{
	pci_bar_handle = PCI_BAR_HANDLE_INIT;
}

/*
 * destructor.
 */
PCIHandler::~PCIHandler()
{

}

/*
 *	Attach the handler a to pci bar.
 */
void PCIHandler::attach(int slot_id, int pf_id, int bar_id)
{
	int rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
	if (rc)
	{
		throw runtime_error("fpga_pci_attach() failed. error code: " + to_string(rc) + "\r\n");
	}
}

/*
 * Set the value at the address.
 */
void PCIHandler::poke(uint64_t address, uint32_t value)
{
	int rc = fpga_pci_poke(pci_bar_handle, address, value);
	if (rc) 
	{
		throw runtime_error("fpga_pci_poke() failed. error code: " + to_string(rc) + "\r\n");
	}
}

/*
 * Get the value at the address.
 */
uint32_t PCIHandler::peek(uint64_t address)
{
	uint32_t value;
	int rc = fpga_pci_peek(pci_bar_handle, address, &value);
	if (rc) 
	{
		throw runtime_error("fpga_pci_peek() failed. error code: " + to_string(rc) + "\r\n");
	}
	return value;
}













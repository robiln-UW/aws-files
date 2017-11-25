/**
 *	pcihandler.h	
 *
 *	@author Tommy Jung
 *	@version 1.0
 */

#ifndef PCI_HANDLER_H
#define PCI_HANDLER_H

#include <fpga_pci.h>
using namespace std;


class PCIHandler
{
	private:
		pci_bar_handle_t pci_bar_handle;

	public:
		PCIHandler();
		~PCIHandler();
		void attach(int slot_id, int pf_id, int bar_id);
		void poke(uint64_t address, uint32_t value);
		uint32_t peek(uint64_t address);
		
};

#endif

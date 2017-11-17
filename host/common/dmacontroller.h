#ifndef DMA_CONTROLLER_H
#define DMA_CONTROLLER_H

#include <cstdlib>
#include <unistd.h>

class DMAController
{
	private:
		int _fd;
	public:
		DMAController();
		~DMAController();
		void init(int slot_id);
		void write(char * buf, size_t buf_size, int channel, size_t offset);
		void read(char * buf, size_t buf_size, int channel, size_t offset);
};


#endif

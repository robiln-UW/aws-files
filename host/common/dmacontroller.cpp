#define	MEM_16G		(1ULL << 34)
#define DMA_OFFSET 0x10000000

#include <iostream>
#include <stdexcept>
#include <string>
#include <fcntl.h>
#include "dmacontroller.h"
using namespace std;



/*
 * default constructor.
 */
DMAController::DMAController()
{
	_fd = -1;
}

/*
 * destructor.
 */
DMAController::~DMAController()
{
	if (_fd >= 0)
	{
		close(_fd);
	}
}

/*
 * open the EDMA file descriptor.
 */
void DMAController::init(int slot_id)
{
	int rc;
	char device_file_name[256];
	
	sprintf(device_file_name, "/dev/edma%i_queue_0", slot_id);

	_fd = open(device_file_name, O_RDWR);

	if (_fd < 0)
	{
		throw runtime_error("failed to open /dev/edma" + to_string(slot_id) +
			"_queue_0. error_code: " + to_string(_fd) + "\r\n");
	} 
}


/*
 * write the content of the buffer to DRAM.
 */
void DMAController::write(char * buf, size_t buf_size, int channel, size_t offset)
{
	if (_fd < 0) throw runtime_error("File descriptor is not open.\r\n");

	int rc;
	size_t write_offset = 0;
	
	while (write_offset < buf_size)
	{
		rc = pwrite(_fd,
			buf + write_offset,
			buf_size - write_offset, 
			DMA_OFFSET + channel*MEM_16G + offset + write_offset);
		
		if (rc < 0)
		{
			throw runtime_error("pwrite() failed. error_code: " + to_string(rc) + "\r\n");
		}

	 	write_offset += rc;
	}

	fsync(_fd);
}

/*
 *	read from DRAM and write to the buffer.
 */
void DMAController::read(char * buf, size_t buf_size, int channel, size_t offset)
{
	if (_fd < 0) throw runtime_error("File descriptor is not open.\r\n");

	int rc;
	size_t read_offset = 0;

	while (read_offset < buf_size)
	{
		rc = pread(_fd,
			buf + read_offset,
			buf_size - read_offset,
			DMA_OFFSET + channel*MEM_16G + offset + read_offset);

		if (rc < 0)
		{
			throw runtime_error("pread() failed. error_code: " + to_string(rc) + "\r\n");
		}

		read_offset += rc;
	}
}









add_wave /card/fpga/CL /card/fpga/CL/sh_ocl_bus /card/fpga/CL/dma_pcis_bus \
	/card/fpga/CL/MOCK_DRAM_A /card/fpga/CL/MOCK_DRAM_B /card/fpga/CL/MOCK_DRAM_C /card/fpga/CL/MOCK_DRAM_D \
	/card/fpga/CL/DRAM_INTERCONNECT \
	/card/fpga/CL/ddr_a_bus  /card/fpga/CL/ddr_b_bus /card/fpga/CL/ddr_c_bus  /card/fpga/CL/ddr_d_bus \
	/card/fpga/CL/DRAM_INTERCONNECT/dma_pcis_bus_q \
	/card/fpga/CL/mem_ctrl_bus /card/fpga/CL/MEM_CTRL \
	/card/fpga/CL/DRAM_INTERCONNECT/src_a_bus /card/fpga/CL/DRAM_INTERCONNECT/dst_a_bus \
	/card/fpga/CL/DRAM_INTERCONNECT/src_b_bus /card/fpga/CL/DRAM_INTERCONNECT/dst_b_bus \
	/card/fpga/CL/DRAM_INTERCONNECT/src_d_bus /card/fpga/CL/DRAM_INTERCONNECT/dst_d_bus 

run 200 us 
quit

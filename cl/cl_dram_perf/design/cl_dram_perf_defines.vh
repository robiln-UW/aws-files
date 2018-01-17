/**	
 *	cl_dram_perf_defines.vh
 *
 *	@author Tommy Jung
 */


`ifndef CL_DRAM_PERF
`define CL_DRAM_PERF

`define CL_NAME cl_dram_perf
`define FPGA_LESS_RST

`endif

`define START_ADDR_REG_ADDR 32'h0000_0500
`define BURST_LEN_REG_ADDR 32'h0000_0504
`define WRITE_VAL_REG_ADDR 32'h0000_0508
`define RHASH_REG_ADDR 32'h0000_050c
`define RW_EN_REG_ADDR 32'h0000_0510
`define RW_DONE_REG_ADDR 32'h0000_0514
`define RD_CLK_COUNT_REG_ADDR 32'h0000_0518
`define WR_CLK_COUNT_REG_ADDR 32'h0000_051c

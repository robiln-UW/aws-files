/**
 *	axi_lite_bus_t.sv
 *	AXI-LITE interface
 *
 *	@author: Tommy Jung
 */

`ifndef AXI_LITE_BUS_T
`define AXI_LITE_BUS_T
interface axi_lite_bus_t;

	logic[31:0] awaddr;
	logic awvalid;
	logic awready;

	logic[31:0] wdata;
	logic[3:0] wstrb;
	logic wvalid;
	logic wready;
	 
	logic[1:0] bresp;
	logic bvalid;
	logic bready;
	 
	logic[31:0] araddr;
	logic arvalid;
	logic arready;
	 
	logic[31:0] rdata;
	logic[1:0] rresp;
	logic rvalid;
	logic rready;

	modport master (
		input awaddr, awvalid, 
		output awready,
		input wdata, wstrb, wvalid, 
		output wready,
		output bresp, bvalid, 
		input bready,
		input araddr, arvalid, 
		output arready,
		output rdata, rresp, rvalid, 
		input rready
	);

    modport slave (
		output awaddr, awvalid,
		input awready,
 		output wdata, wstrb, wvalid,
		input wready,
        input bresp, bvalid,
		output bready,
        output araddr, arvalid,
		input arready,
        input rdata, rresp, rvalid,
		output rready
	);

endinterface
`endif

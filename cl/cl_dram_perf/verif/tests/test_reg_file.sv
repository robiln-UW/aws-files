module test_reg_file();

	`define START_ADDR_REG_ADDR 32'h0000_0500
	`define BURST_LEN_REG_ADDR 32'h0000_0504
	`define WRITE_VAL_REG_ADDR 32'h0000_0508
	
	import tb_type_defines_pkg::*;
	logic [31:0] rdata;

	initial begin
		
		tb.power_up();

		// testing START_ADDR
		tb.poke(
			.addr(`START_ADDR_REG_ADDR),
			.data(32'habcd_1234),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`START_ADDR_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'habcd_1234)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);

		tb.poke(
			.addr(`START_ADDR_REG_ADDR),
			.data(32'hdddd_dddd),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`START_ADDR_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'hdddd_dddd)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);
		
		// testing BURST_LEN
		tb.poke(
			.addr(`BURST_LEN_REG_ADDR),
			.data(32'heeee_cccc),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`BURST_LEN_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'heeee_cccc)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);

		tb.poke(
			.addr(`BURST_LEN_REG_ADDR),
			.data(32'haaaa_3333),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`BURST_LEN_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'haaaa_3333)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);
		
		// testing WRITE_VAL
		tb.poke(
			.addr(`WRITE_VAL_REG_ADDR),
			.data(32'h_7777_8888),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`WRITE_VAL_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'h7777_8888)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);

		tb.poke(
			.addr(`WRITE_VAL_REG_ADDR),
			.data(32'h9988_8877),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.peek(
			.addr(`WRITE_VAL_REG_ADDR),
			.data(rdata),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);	

		if (rdata == 32'h9988_8877)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);


	   	tb.kernel_reset();
     	tb.power_down();
      
     	$finish;
   end
endmodule

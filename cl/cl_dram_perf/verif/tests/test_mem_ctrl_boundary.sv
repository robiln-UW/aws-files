module test_mem_ctrl_boundary();

	`define START_ADDR_REG_ADDR 32'h0000_0500
	`define BURST_LEN_REG_ADDR 32'h0000_0504
	`define WRITE_VAL_REG_ADDR 32'h0000_0508

	import tb_type_defines_pkg::*;
	logic[63:0] cl_addr = 64'h3ffffff00;
	logic[63:0] src_addr;
	logic[63:0] dst_addr;
	int timeout_count;
	logic[3:0] status;
	int len0 = 64*8;
	logic[7:0] rdata;
	logic[7:0] wdata;
	logic[15:0] vled;

	initial begin

		tb.power_up(
			.clk_recipe_a(ClockRecipe::A1),
			.clk_recipe_b(ClockRecipe::B0),
			.clk_recipe_c(ClockRecipe::C0)
		);
	
		tb.nsec_delay(100);
		tb.poke_stat(.addr(8'h0c), .ddr_idx(0), .data(32'h0000_0000));
       	tb.poke_stat(.addr(8'h0c), .ddr_idx(1), .data(32'h0000_0000));
		tb.poke_stat(.addr(8'h0c), .ddr_idx(2), .data(32'h0000_0000));
		tb.nsec_delay(27000);	

		// deassert rd/wr enable
		tb.set_virtual_dip_switch(.dip(16'h0000));
	
		// set up buffer and queue transfer
		src_addr = 64'h0;
		wdata = 0;
		tb.que_buffer_to_cl(.chan(0), .src_addr(src_addr), .cl_addr(cl_addr), .len(len0));

		for (int i = 0; i < len0; i++) begin
			tb.hm_put_byte(.addr(src_addr), .d(wdata));
			wdata += 1;
			src_addr++;
		end
		#40ns;
		
		// start transfer from buffer to cl
		tb.start_que_to_cl(.chan(0));
		timeout_count = 0;
		do begin
			status[0] = tb.is_dma_to_cl_done(.chan(0));
			#10ns;
			timeout_count++;
		end while ((status[0] != 1) && timeout_count < 100);

		if (timeout_count >= 100) begin
			$display("[%t] transfer from buffer to cl timed out.", $realtime);
		end

		// set start_addr, burst_len
		tb.poke(
			.addr(`START_ADDR_REG_ADDR),
			.data(32'h0fff_fffc),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.poke(
			.addr(`BURST_LEN_REG_ADDR),
			.data(32'h0000_0007),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		// assert rd_enable
		tb.set_virtual_dip_switch(.dip(16'h0001));

		timeout_count = 0;
		do begin
			vled = tb.get_virtual_led();	
			timeout_count++;
			#10ns;
		end while ((timeout_count < 200) && vled[0] != 1);

		if (timeout_count >= 200) begin
			$display("[%t] mem_ctrl read timed out.", $realtime);
		end
		else begin
			$display("[%t] mem_ctrl read did not time out. timeout_count = %d", $realtime, timeout_count);
		end

		// deassert rd_enable
		tb.set_virtual_dip_switch(.dip(16'h0000));	

		// set write val
		tb.poke(
			.addr(`WRITE_VAL_REG_ADDR),
			.data(32'hdead_beef),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		// assert wr_enable
		tb.set_virtual_dip_switch(.dip(16'h0002));

		timeout_count = 0;
		do begin
			vled = tb.get_virtual_led();	
			timeout_count++;
			#10ns;
		end while ((timeout_count < 200) && vled[1] != 1);

		if (timeout_count >= 200) begin
			$display("[%t] mem_ctrl write timed out.", $realtime);
		end
		else begin
			$display("[%t] mem_ctrl write did not time out. timeout_count = %d", $realtime, timeout_count);
		end

		// deassert wr_enable
		tb.set_virtual_dip_switch(.dip(16'h0000));

	   	     
		// transfer data from cl to buffer
		dst_addr = (1 << 12);
		tb.que_cl_to_buffer(.chan(0), .dst_addr(dst_addr), .cl_addr(cl_addr), .len(len0));
		#10ns;

		tb.start_que_to_buffer(.chan(0));

		timeout_count = 0;
		do begin
			status[0] = tb.is_dma_to_buffer_done(.chan(0));
			#10ns;
			timeout_count++;
		end while ((status[0] != 1) && timeout_count < 200);

	 	if (timeout_count >= 200) begin
			$display("[%t] transfer from cl to buffer timed out.", $realtime);
		end
		
		// check buffer
		for (int i = 0; i < len0; i++) begin
			rdata = tb.hm_get_byte(.addr(dst_addr + i));
			$display("addr: %0x, rdata: %0x", dst_addr+i, rdata);
		end
	
		tb.kernel_reset();
		tb.power_down();
     	$finish;
   end
endmodule

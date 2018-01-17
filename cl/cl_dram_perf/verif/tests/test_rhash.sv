module test_rhash();

	`define START_ADDR_REG_ADDR 32'h0000_0500
	`define BURST_LEN_REG_ADDR 32'h0000_0504
	`define WRITE_VAL_REG_ADDR 32'h0000_0508
	`define RHASH_REG_ADDR 32'h0000_050c

	import tb_type_defines_pkg::*;
	logic[63:0] cl_addr = 0;
	logic[63:0] src_addr;
	logic[63:0] dst_addr;
	int timeout_count;
	logic[3:0] status;
	int len0 = 64*2;
	logic[7:0] rdata;
	logic[7:0] wdata;
	logic[15:0] vled;
	logic[31:0] rhash1;
	logic[31:0] rhash2;	

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
			wdata = (wdata << 1) + 7;
			src_addr++;
		end
		#40ns;

		// calculate rhash
		rhash1 = 0;
		for (int i = 0; i < len0/4; i++) begin
			rhash1[31:24] = rhash1[31:24] ^ tb.hm_get_byte(.addr(4*i+3));
			rhash1[23:16] = rhash1[23:16] ^ tb.hm_get_byte(.addr(4*i+2));
			rhash1[15:8] = rhash1[15:8] ^ tb.hm_get_byte(.addr(4*i+1));
			rhash1[7:0] = rhash1[7:0] ^ tb.hm_get_byte(.addr(4*i));
		end
		$display("rhash1: %x", rhash1);	
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
			.data(32'h0000_0000),
			.id(6'h0),
			.size(DataSize::UINT32),
			.intf(AxiPort::PORT_OCL)
		);

		tb.poke(
			.addr(`BURST_LEN_REG_ADDR),
			.data(32'h0000_0001),
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

		tb.peek_ocl(
			.addr(`RHASH_REG_ADDR),
			.data(rhash2)
		);	

		$display("actual: %x", rhash2);
		tb.kernel_reset();
		tb.power_down();
     	$finish;
   end
endmodule

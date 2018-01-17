/**
 *	test_mem_ctrl.sv
 *
 *	@author: Tommy Jung
 */

module test_mem_ctrl();

	import tb_type_defines_pkg::*;
	logic[63:0] cl_addr = 0;
	logic[63:0] src_addr;
	logic[63:0] dst_addr;
	int timeout_count;
	logic[3:0] status;
	int len0 = 64*1;
	logic[7:0] rdata;
	logic[7:0] wdata;
	logic[31:0] ocl_read;
	logic[31:0] expected_rhash;

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
		tb.poke_ocl(.addr(`RW_EN_REG_ADDR), .data(32'b0));
	
		// set up buffer and queue transfer
		src_addr = 64'h0;
		wdata = 0;
		tb.que_buffer_to_cl(.chan(0), .src_addr(src_addr), .cl_addr(cl_addr), .len(len0));

		for (int i = 0; i < len0; i++) begin
			tb.hm_put_byte(.addr(src_addr), .d(wdata));
			wdata = (wdata << 2) + 5;
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
		tb.poke_ocl(.addr(`START_ADDR_REG_ADDR), .data(32'h0000_0000));
		tb.poke_ocl(.addr(`BURST_LEN_REG_ADDR), .data(32'h0000_0000));

		// assert rd_enable
		tb.poke_ocl(.addr(`RW_EN_REG_ADDR), .data(32'h0000_0001));

		ocl_read = 0;
		timeout_count = 0;
		do begin
			tb.peek_ocl(.addr(`RW_DONE_REG_ADDR), .data(ocl_read));	
			timeout_count++;
			#10ns;
		end while ((timeout_count < 200) && ocl_read[0] != 1);

		if (timeout_count >= 200) begin
			$display("[%t] mem_ctrl read timed out.", $realtime);
		end
		else begin
			$display("[%t] mem_ctrl read did not time out. timeout_count = %d", $realtime, timeout_count);
		end
		
		tb.peek_ocl(.addr(`RD_CLK_COUNT_REG_ADDR), .data(ocl_read));
		$display("[%t] rd_clk_count = %d ", $realtime, ocl_read);

		// deassert rd_enable
		tb.poke_ocl(.addr(`RW_EN_REG_ADDR), .data(32'b0));
	
		// calculate rhash
		expected_rhash = 0;
		for (int i = 0; i < len0; i++) begin
			rdata = tb.hm_get_byte(.addr(i));
			case (i % 4)
				0 : expected_rhash = expected_rhash ^ {24'b0, rdata};
				1 :	expected_rhash = expected_rhash ^ {16'b0, rdata, 8'b0};
				2 :	expected_rhash = expected_rhash ^ {8'b0, rdata, 16'b0};
				3 :	expected_rhash = expected_rhash ^ {rdata, 24'b0};
			endcase
		end
		$display("[%t] expected rhash = %x", $realtime, expected_rhash);

		// read rhash
		tb.peek_ocl(.addr(`RHASH_REG_ADDR), .data(ocl_read));
		$display("[%t] actual rhash = %x", $realtime, ocl_read);

		// set write val
		tb.poke_ocl(.addr(`WRITE_VAL_REG_ADDR),.data(32'hdead_beef));

		// assert wr_enable
		tb.poke_ocl(.addr(`RW_EN_REG_ADDR), .data(32'h2));

		ocl_read = 0;
		timeout_count = 0;
		do begin
			tb.peek_ocl(.addr(`RW_DONE_REG_ADDR), .data(ocl_read));	
			timeout_count++;
			#10ns;
		end while ((timeout_count < 200) && ocl_read[1] != 1);

		if (timeout_count >= 200) begin
			$display("[%t] mem_ctrl write timed out.", $realtime);
		end
		else begin
			$display("[%t] mem_ctrl write did not time out. timeout_count = %d", $realtime, timeout_count);
		end

		tb.peek_ocl(.addr(`WR_CLK_COUNT_REG_ADDR), .data(ocl_read));
		$display("[%t] wr_clk_count = %d", $realtime, ocl_read);

		// deassert wr_enable
		tb.poke_ocl(.addr(`RW_EN_REG_ADDR), .data(32'h0));

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
		end while ((status[0] != 1) && timeout_count < 400);

	 	if (timeout_count >= 400) begin
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

module mem_ctrl
(
	input clk,
	input rst_n,
	input rd_enable,
	input wr_enable,
	output rd_done,
	output wr_done,
	input[31:0] start_addr,
	input[31:0] burst_len,
	input[31:0] write_val,
	axi4_bus_t.slave axi
);

// read operation
typedef enum logic[1:0] {
	RD_DONE = 2'd0,
	RD_WAIT = 2'd1,
	RD_ARVALID = 2'd2,
	RD_RREADY = 2'd3
} rd_states;

logic[1:0] rd_curr_state;
logic[1:0] rd_next_state;
logic[31:0] rd_start_addr;
logic[31:0] rd_burst_len;

always_comb begin
	if (rst_n) begin
		case (rd_curr_state)
			RD_DONE: rd_next_state = rd_enable ? RD_DONE : RD_WAIT;
			RD_WAIT: rd_next_state = rd_enable ? RD_ARVALID : RD_WAIT;
			RD_ARVALID: rd_next_state = axi.arready ? RD_RREADY : RD_ARVALID;
			RD_RREADY: rd_next_state = (axi.rlast && axi.rvalid)
				? ((rd_burst_len == 32'hffff_ffff) ? RD_DONE : RD_ARVALID)
				: RD_RREADY;
		endcase
	end
	else begin
		rd_next_state = RD_WAIT;
	end

	// does the burst cross 4KB boundary?
	if (rd_burst_len > 63 || (rd_start_addr % (1<<6)) + rd_burst_len > 63) begin
		axi.arlen = 8'h3f - (rd_start_addr % (1<<6));
	end
	else begin
		axi.arlen = rd_burst_len;
	end

	axi.arid = 16'h0;
	axi.arsize = 3'b110;
	axi.araddr = {28'b0, rd_start_addr[29:0], 6'b0};
	axi.arvalid = (rd_curr_state == RD_ARVALID);
	axi.rready = (rd_curr_state == RD_RREADY);	

end

assign rd_done = (rd_curr_state == RD_DONE);

always_ff @ (posedge clk) begin
	rd_curr_state <= rd_next_state;
	if (rst_n) begin
		if ((rd_curr_state == RD_WAIT) && rd_enable) begin
			rd_start_addr <= {2'b0, start_addr[29:0]};
			rd_burst_len <= {2'b0, burst_len[29:0]};
		end 
		else if ((rd_curr_state == RD_ARVALID) && axi.arready) begin
			rd_start_addr <= rd_start_addr + axi.arlen + 1;
			rd_burst_len <= rd_burst_len - axi.arlen - 1;
		end	
	end
	else begin
		rd_start_addr <= 0;
		rd_burst_len <= 0;
	end
	
end


// write operation
typedef enum logic[2:0] {
	WR_DONE = 3'd0,
	WR_WAIT = 3'd1,
	WR_AWVALID = 3'd2,
	WR_WVALID = 3'd3,
	WR_BREADY = 3'd4
} wr_states;

logic[2:0] wr_curr_state;
logic[2:0] wr_next_state;
logic[31:0] wr_start_addr;
logic[31:0] wr_burst_len;
logic[31:0] wr_burst_count;
logic[31:0] wr_write_val;

always_comb begin
	if (rst_n) begin
		case(wr_curr_state)
			WR_DONE: wr_next_state = wr_enable ? WR_DONE : WR_WAIT;
			WR_WAIT: wr_next_state = wr_enable ? WR_AWVALID : WR_WAIT;
			WR_AWVALID: wr_next_state = axi.awready ? WR_WVALID : WR_AWVALID;
			WR_WVALID: wr_next_state = ((wr_burst_count == 0) && axi.wready) ? WR_BREADY : WR_WVALID;
			WR_BREADY: wr_next_state = axi.bvalid
				? (wr_burst_len == 32'hffff_ffff ? WR_DONE : WR_AWVALID)
				: WR_BREADY;
			default: $display("invalid wr_state: 0x%h", wr_curr_state);
		endcase
	end
	else begin
		wr_next_state = WR_WAIT;
	end
	
	axi.awid = 16'b0;
	axi.awvalid = (wr_curr_state == WR_AWVALID);
	axi.awaddr = {28'b0, wr_start_addr[29:0], 6'b0};
	axi.awsize = 3'b110;

	// does the burst cross 4KB boundary?
	if (wr_burst_len > 63 || (wr_start_addr % (1<<6)) + wr_burst_len > 63) begin
		axi.awlen = 8'h3f - (wr_start_addr % (1<<6));
	end
	else begin
		axi.awlen = wr_burst_len;
	end

	axi.wvalid = (wr_curr_state == WR_WVALID);
	axi.wstrb = {8{8'hff}};
	axi.wlast = (wr_curr_state == WR_WVALID) && (wr_burst_count == 0);		
	axi.wdata = {16{wr_write_val}};	

	axi.bready = (wr_curr_state == WR_BREADY);	
end

assign wr_done = (wr_curr_state == WR_DONE);

always_ff @ (posedge clk) begin
	wr_curr_state <= wr_next_state;
	if (rst_n) begin
		if ((wr_curr_state == WR_WAIT) && wr_enable) begin
			wr_start_addr <= {2'b0, start_addr[29:0]};
			wr_burst_len <= {2'b0, burst_len[29:0]};
			wr_write_val <= write_val;
		end
		else if ((wr_curr_state == WR_AWVALID) && axi.awready) begin
			wr_burst_count <= axi.awlen;
			wr_start_addr <= wr_start_addr + axi.awlen + 1;
			wr_burst_len <= wr_burst_len - axi.awlen - 1;
		end
		else if ((wr_curr_state == WR_WVALID) && axi.wready) begin
			wr_burst_count <= wr_burst_count - 1;
		end
		
	end
	else begin
		wr_start_addr <= 0;
		wr_burst_len <= 0;
		wr_write_val <= 0;
	end
end

endmodule

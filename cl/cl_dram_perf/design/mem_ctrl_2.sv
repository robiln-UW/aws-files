/**
 *	mem_ctrl_2.sv
 *	AXI-4 master to read and write from DRAM.
 *	Read address and data channels are independent.
 *	Write address, data and response channels are also independent. 
 *
 * 	@author Tommy Jung
 */

module mem_ctrl_2
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
	output[31:0] rhash,
	output[31:0] rd_clk_count,
	output[31:0] wr_clk_count,
	axi4_bus_t.slave axi
);

// read address channel
typedef enum logic[1:0]
{
	RD_DONE = 2'd0,
	RD_WAIT = 2'd1,
	RD_ARVALID = 2'd2,
	RD_WAIT_DATA = 2'd3
} rd_states;

logic[1:0] rd_curr_state;
logic[1:0] rd_next_state;
logic[31:0] rd_start_addr;
logic[31:0] rd_start_addr_next;
logic[31:0] rd_burst_len;
logic[31:0] rd_burst_len_next;
logic[31:0] rd_burst_left;
logic[31:0] rhash_reg;
logic[31:0] rd_clk_count_reg;

logic rd_fifo_full;
logic rd_fifo_empty;
logic rd_fifo_write_en;
logic rd_fifo_read_en;
logic[7:0] rd_fifo_data_in;
logic[7:0] rd_fifo_data_out;
sync_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) RD_FIFO (
	.clk(clk),
	.rst_n(rst_n),
	.write_en(rd_fifo_write_en),
	.read_en(rd_fifo_read_en),
	.data_in(rd_fifo_data_in),
	.data_out(rd_fifo_data_out),
	.full(rd_fifo_full),
	.empty(rd_fifo_empty)
);

assign axi.arlen = (rd_burst_len > 63 || (rd_start_addr % (1<<6)) + rd_burst_len > 63)
	? 8'h3f - (rd_start_addr % (1<<6))
	: rd_burst_len;
assign rd_burst_len_next = rd_burst_len - axi.arlen - 1;
assign rd_start_addr_next = rd_start_addr + axi.arlen + 1;

assign rd_fifo_data_in = axi.arlen;
assign rd_fifo_write_en = (rd_curr_state == RD_ARVALID) && axi.arready && !rd_fifo_full; 

assign axi.arid = 16'h0;
assign axi.arsize = 3'b110;
assign axi.araddr = {28'b0, rd_start_addr[29:0], 6'b0};
assign axi.arvalid = (rd_curr_state == RD_ARVALID) && !rd_fifo_full;


always_comb begin
	if (rst_n) begin
		case (rd_curr_state)
			RD_DONE: rd_next_state = rd_enable ? RD_DONE : RD_WAIT;
			RD_WAIT: rd_next_state = rd_enable ? RD_ARVALID : RD_WAIT;
			RD_ARVALID: rd_next_state = (axi.arready && (rd_burst_len_next == 32'hffff_ffff) && !rd_fifo_full)
				? RD_WAIT_DATA
				: RD_ARVALID;
			RD_WAIT_DATA: rd_next_state = (rd_burst_left == 32'hffff_ffff) ? RD_DONE : RD_WAIT_DATA;
		endcase
	end
	else begin
		rd_next_state = RD_WAIT; 
	end

end

assign rd_done = (rd_curr_state == RD_DONE);
assign rhash = rhash_reg;
assign rd_clk_count = rd_clk_count_reg;

always_ff @ (posedge clk) begin
	rd_curr_state <= rd_next_state;

	if (rst_n) begin
		if ((rd_curr_state == RD_WAIT) && rd_enable) begin
			rd_start_addr <= {2'b0, start_addr[29:0]};
			rd_burst_len <= {2'b0, burst_len[29:0]};
			rd_burst_left <= {2'b0, burst_len[29:0]};
			rhash_reg <= 0;
			rd_clk_count_reg <= 0;
		end
		else if ((rd_curr_state == RD_ARVALID) && axi.arready && !rd_fifo_full) begin
			rd_start_addr <= rd_start_addr_next;
			rd_burst_len <= rd_burst_len_next;	
		end
	end 
	else begin
		rd_start_addr <= 0;
		rd_burst_len <= 0;
		rd_burst_left <= 0;
		rhash_reg <= 0;
		rd_clk_count_reg <= 0;
	end
	
	if ((rd_curr_state != RD_WAIT) && (rd_curr_state != RD_DONE)) begin
		rd_clk_count_reg <= rd_clk_count_reg + 1;
	end
end

// read data channel
typedef enum logic {
	RD_DATA_WAIT = 1'd0,
	RD_DATA_RREADY = 1'd1	
} rd_data_states;

logic rd_data_curr_state;
logic rd_data_next_state;
logic[7:0] rd_arlen_cache;
always_comb begin
	if (rst_n) begin
		case (rd_data_curr_state)
			RD_DATA_WAIT: rd_data_next_state = rd_fifo_empty ? RD_DATA_WAIT : RD_DATA_RREADY;
			RD_DATA_RREADY: rd_data_next_state = axi.rvalid && axi.rlast ? RD_DATA_WAIT : RD_DATA_RREADY;
		endcase
	end
	else begin
		rd_data_next_state = RD_DATA_WAIT;
	end
	
	rd_fifo_read_en = (rd_data_curr_state == RD_DATA_WAIT) && !rd_fifo_empty;
	axi.rready = (rd_data_curr_state == RD_DATA_RREADY);  
end

always_ff @ (posedge clk) begin
	rd_data_curr_state <= rd_data_next_state;

	if (rst_n) begin
		if ((rd_data_curr_state == RD_DATA_WAIT) && !rd_fifo_empty) begin
			rd_arlen_cache <= rd_fifo_data_out;
		end 
		else if ((rd_data_curr_state == RD_DATA_RREADY) && axi.rvalid) begin
			rhash_reg <= rhash_reg ^ axi.rdata[31:0] ^ axi.rdata[63:32] ^ axi.rdata[95:64] ^ axi.rdata[127:96]
				^ axi.rdata[159:128] ^ axi.rdata[191:160] ^ axi.rdata[223:192] ^ axi.rdata[255:224]
				^ axi.rdata[287:256] ^ axi.rdata[319:288] ^ axi.rdata[351:320] ^ axi.rdata[383:352]
				^ axi.rdata[415:384] ^ axi.rdata[447:416] ^ axi.rdata[479:448] ^ axi.rdata[511:480];
			if (axi.rlast) begin
				rd_burst_left <= rd_burst_left - rd_arlen_cache - 1;
			end
		end	
	end
	else begin
		rd_arlen_cache <= 0;
	end
end

// write addr channel
typedef enum logic[1:0] {
	WR_DONE = 2'd0,
	WR_WAIT = 2'd1,
	WR_AWVALID = 2'd2,
	WR_WAIT_RESP = 2'd3	
} wr_states;

logic[1:0] wr_curr_state;
logic[1:0] wr_next_state;
logic[31:0] wr_start_addr;
logic[31:0] wr_start_addr_next;
logic[31:0] wr_burst_len;
logic[31:0] wr_burst_len_next;
logic[31:0] wr_burst_left;
logic[31:0] wr_write_val;
logic[31:0] wr_clk_count_reg;

logic fifo_full_1;
logic fifo_empty_1;
logic fifo_write_en_1;
logic fifo_read_en_1;
logic[7:0] fifo_data_in_1;
logic[7:0] fifo_data_out_1;
sync_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) WR_FIFO_1(
	.clk(clk),
	.rst_n(rst_n),
	.write_en(fifo_write_en_1),
	.read_en(fifo_read_en_1),
	.data_in(fifo_data_in_1),
	.data_out(fifo_data_out_1),
	.full(fifo_full_1),
	.empty(fifo_empty_1)
);
assign axi.awid = 16'b0;
assign axi.awsize = 3'b110;
assign axi.awlen = (wr_burst_len > 63 || (wr_start_addr % (1<<6)) + wr_burst_len > 63)
	? 8'h3f - (wr_start_addr % (1<<6))
	: wr_burst_len;

assign wr_burst_len_next = wr_burst_len - axi.awlen - 1;
assign wr_start_addr_next = wr_start_addr + axi.awlen + 1;

always_comb begin
	if (rst_n) begin
		case (wr_curr_state)
			WR_DONE: wr_next_state = wr_enable ? WR_DONE : WR_WAIT;
			WR_WAIT: wr_next_state = wr_enable ? WR_AWVALID : WR_WAIT;
			WR_AWVALID:	wr_next_state = (!fifo_full_1 && axi.awready && (wr_burst_len_next == 32'hffff_ffff))
				? WR_WAIT_RESP
				: WR_AWVALID;
			WR_WAIT_RESP: wr_next_state = (wr_burst_left == 32'hffff_ffff) ? WR_DONE : WR_WAIT_RESP;
		endcase	
	end 
	else begin
		wr_next_state = WR_WAIT;	
	end

	axi.awvalid = (wr_curr_state == WR_AWVALID) && !fifo_full_1; 
	axi.awaddr = {28'b0, wr_start_addr[29:0], 6'b0};

	fifo_data_in_1 = axi.awlen;	
	fifo_write_en_1 = (wr_curr_state == WR_AWVALID) && axi.awready && !fifo_full_1;
end

assign wr_done = (wr_curr_state == WR_DONE);
assign wr_clk_count = wr_clk_count_reg;

always_ff @ (posedge clk) begin
	wr_curr_state <= wr_next_state;	

	if (rst_n) begin
		if ((wr_curr_state == WR_WAIT) && wr_enable) begin
			wr_start_addr <= {2'b0, start_addr[29:0]};
			wr_burst_len <= {2'b0, burst_len[29:0]};
			wr_burst_left <= {2'b0, burst_len[29:0]};
			wr_write_val <= write_val;
			wr_clk_count_reg <= 0;
		end
		else if ((wr_curr_state == WR_AWVALID) && axi.awready && !fifo_full_1) begin
			wr_start_addr <= wr_start_addr_next;
			wr_burst_len <= wr_burst_len_next;
		end
		
		if ((wr_curr_state != WR_WAIT) && (wr_curr_state != WR_DONE)) begin
			wr_clk_count_reg <= wr_clk_count_reg + 1;
		end	
	end
	else begin
		wr_start_addr <= 0;
		wr_burst_len <= 0;
		wr_write_val <= 0;
		wr_clk_count_reg <= 0;
	end
end

// write data channel
typedef enum logic
{
	WR_DATA_WAIT = 1'b0,
	WR_DATA_WVALID = 1'b1
} wr_data_states; 

logic wr_data_curr_state;
logic wr_data_next_state;
logic[7:0] wr_awlen_count;
logic[7:0] wr_awlen_cache;

logic fifo_full_2;
logic fifo_empty_2;
logic fifo_write_en_2;
logic fifo_read_en_2;
logic[7:0] fifo_data_in_2;
logic[7:0] fifo_data_out_2;
sync_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) WR_FIFO_2(
	.clk(clk),
	.rst_n(rst_n),
	.write_en(fifo_write_en_2),
	.read_en(fifo_read_en_2),
	.data_in(fifo_data_in_2),
	.data_out(fifo_data_out_2),
	.full(fifo_full_2),
	.empty(fifo_empty_2)
);

always_comb begin
	if (rst_n) begin
		case (wr_data_curr_state) 
			WR_DATA_WAIT: wr_data_next_state = (fifo_empty_1 || fifo_full_2) ? WR_DATA_WAIT : WR_DATA_WVALID;
			WR_DATA_WVALID: wr_data_next_state = ((wr_awlen_count == 0) && axi.wready) ? WR_DATA_WAIT : WR_DATA_WVALID;
		endcase
	end
	else begin
		wr_data_next_state = WR_DATA_WAIT; 
	end
	
	fifo_read_en_1 = (wr_data_curr_state == WR_DATA_WAIT) && !fifo_empty_1 && !fifo_full_2;
	axi.wvalid = (wr_data_curr_state == WR_DATA_WVALID);
	axi.wstrb = {8{8'hff}};
	axi.wlast = (wr_data_curr_state == WR_DATA_WVALID) && (wr_awlen_count == 0);		
	axi.wdata = {16{wr_write_val}};	
	fifo_data_in_2 = wr_awlen_cache;
	fifo_write_en_2 = (wr_data_curr_state == WR_DATA_WVALID) && (wr_awlen_count == 0) && axi.wready;	
end

always_ff @ (posedge clk) begin
	wr_data_curr_state <= wr_data_next_state;
	
	if (rst_n) begin
		if ((wr_data_curr_state == WR_DATA_WAIT) && !fifo_empty_1 && !fifo_full_2) begin
			wr_awlen_count <= fifo_data_out_1;
			wr_awlen_cache <= fifo_data_out_1;
		end
		else if ((wr_data_curr_state == WR_DATA_WVALID) && axi.wready) begin
			wr_awlen_count <= wr_awlen_count - 1;				
		end	
	end
	else begin
		wr_awlen_count <= 0;
		wr_awlen_cache <= 0;	
	end
end

// write response channel
typedef enum logic
{
	WR_RESP_WAIT = 1'b0,
	WR_RESP_BREADY = 1'b1	
} wr_resp_states;

logic wr_resp_curr_state;
logic wr_resp_next_state;
logic[7:0] wr_awlen_cache_2;

always_comb begin
	if (rst_n) begin
		case (wr_resp_curr_state)
			WR_RESP_WAIT: wr_resp_next_state = fifo_empty_2 ? WR_RESP_WAIT : WR_RESP_BREADY;
			WR_RESP_BREADY: wr_resp_next_state = axi.bvalid ? WR_RESP_WAIT : WR_RESP_BREADY; 
		endcase
	end 	
	else begin
		wr_resp_next_state = WR_RESP_WAIT;	
	end
	
	fifo_read_en_2 = (wr_resp_curr_state == WR_RESP_WAIT) && !fifo_empty_2; 
	axi.bready = (wr_resp_curr_state == WR_RESP_BREADY);
end

always_ff @ (posedge clk) begin
	wr_resp_curr_state <= wr_resp_next_state;
	
	if (rst_n) begin
		if ((wr_resp_curr_state == WR_RESP_WAIT) && !fifo_empty_2) begin
			wr_awlen_cache_2 <= fifo_data_out_2;
		end
		else if ((wr_resp_curr_state == WR_RESP_BREADY) && axi.bvalid) begin
			wr_burst_left <= wr_burst_left - wr_awlen_cache_2 - 1;	
		end
	end
end

endmodule

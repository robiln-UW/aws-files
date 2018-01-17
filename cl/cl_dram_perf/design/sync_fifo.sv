/**
 *  sync_fifo.sv
 *	Synchronous first-in, first-out pipeline.
 *
 *	@author Tommy Jung
 */

module sync_fifo #(parameter DATA_WIDTH=1, parameter ADDR_WIDTH=4) 
(
	input clk,
	input rst_n,
	input write_en,
	input read_en,
	input[DATA_WIDTH-1:0] data_in,
	output[DATA_WIDTH-1:0] data_out,
	output full,
	output empty	
);

logic[DATA_WIDTH-1:0] pipe[0:ADDR_WIDTH-1];
logic[ADDR_WIDTH:0] wr_pointer;
logic[ADDR_WIDTH:0] rd_pointer;

assign empty = (wr_pointer == rd_pointer);
assign full = (wr_pointer[ADDR_WIDTH-1:0] == rd_pointer[ADDR_WIDTH-1:0]) 
	&& (wr_pointer[ADDR_WIDTH:ADDR_WIDTH] != rd_pointer[ADDR_WIDTH:ADDR_WIDTH]);
assign data_out = pipe[rd_pointer[ADDR_WIDTH-1:0]];

always_ff @ (posedge clk) begin
	if (rst_n) begin
		if (!full && write_en) begin
			pipe[wr_pointer[ADDR_WIDTH-1:0]] <= data_in;
			wr_pointer <= wr_pointer + 1;
		end

		if (!empty && read_en) begin
			rd_pointer <= rd_pointer + 1;
		end		
	end
	else begin
		wr_pointer <= 0;
		rd_pointer <= 0;
		for (int i = 0; i < (1 << ADDR_WIDTH); i=i+1) begin
			pipe[i] <= 0;
		end	
	end
end

endmodule

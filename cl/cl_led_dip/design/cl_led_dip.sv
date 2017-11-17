// top-level module
module cl_led_dip
(
	`include "cl_ports.vh"
);

`include "cl_common_defines.vh"
`include "cl_id_defines.vh"
`include "cl_led_dip_defines.vh"

logic rst_main_n_sync;
// Tie off unused signals
`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_sh_ocl_template.inc"

assign cl_sh_id0[31:0] = `CL_SH_ID0;
assign cl_sh_id1[31:0] = `CL_SH_ID1;

// Reset synchronization
logic pre_sync_rst_n;

always_ff @(negedge rst_main_n or posedge clk_main_a0)
	if (!rst_main_n) begin
     	pre_sync_rst_n  <= 0;
     	rst_main_n_sync <= 0;
  	end 
	else begin
      	pre_sync_rst_n  <= 1;
      	rst_main_n_sync <= pre_sync_rst_n;
  	end

// Hello World virtual DIP/LED
logic[15:0] vdip_q;
always_ff @(posedge clk_main_a0 or negedge rst_main_n_sync)
	if (!rst_main_n_sync) begin
		vdip_q <= 16'b0;	
	end
	else begin
		vdip_q <= sh_cl_status_vdip[15:0];
	end

assign cl_sh_status_vled = {vdip_q[3:0], vdip_q[7:4], vdip_q[11:8], vdip_q[15:12]};

//-------------------------------------------
// Tie-Off Global Signals
//-------------------------------------------
`ifndef CL_VERSION
   `define CL_VERSION 32'hee_ee_ee_00
`endif  

assign cl_sh_status0[31:0] =  32'h0000_0FF0;
assign cl_sh_status1[31:0] = `CL_VERSION;

endmodule






module cl_dram_perf
(
	`include "cl_ports.vh"
);

`include "cl_common_defines.vh"
`include "cl_id_defines.vh"
`include "cl_dram_perf_defines.vh"

logic rst_main_n_sync;
// Tie off unused signals
//`include "unused_flr_template.inc"
//`include "unused_ddr_a_b_d_template.inc"
//`include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
//`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
//`include "unused_sh_ocl_template.inc"

assign cl_sh_id0[31:0] = `CL_SH_ID0;
assign cl_sh_id1[31:0] = `CL_SH_ID1;
assign cl_sh_status0 = 32'h0000_0FF0;
assign cl_sh_status1 = 32'heeee_ee00;

// reset synchronization
logic pre_sync_rst_n;
(* dont_touch = "true" *) logic pipe_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (
	.clk(clk_main_a0),
	.rst_n(1'b1),
	.in_bus(rst_main_n),
	.out_bus(pipe_rst_n)
);

always_ff @(negedge pipe_rst_n or posedge clk_main_a0)
	if (!pipe_rst_n) begin
     	pre_sync_rst_n  <= 0;
     	rst_main_n_sync <= 0;
  	end 
	else begin
      	pre_sync_rst_n  <= 1;
      	rst_main_n_sync <= pre_sync_rst_n;
  	end


logic sh_cl_flr_assert_q;
always_ff @ (posedge clk_main_a0) begin
	if (!rst_main_n_sync) begin
		sh_cl_flr_assert_q <= 0;
		cl_sh_flr_done <= 0;
	end
	else begin
		sh_cl_flr_assert_q <= sh_cl_flr_assert;
		cl_sh_flr_done <= sh_cl_flr_assert_q && !cl_sh_flr_done;
	end
end

// OCL reg_file
axi_lite_bus_t sh_ocl_bus();

assign sh_ocl_bus.awvalid = sh_ocl_awvalid;
assign sh_ocl_bus.awaddr = sh_ocl_awaddr;
assign ocl_sh_awready = sh_ocl_bus.awready;

assign sh_ocl_bus.wvalid = sh_ocl_wvalid;
assign sh_ocl_bus.wdata = sh_ocl_wdata;
assign sh_ocl_bus.wstrb = sh_ocl_wstrb;
assign ocl_sh_wready = sh_ocl_bus.wready;

assign ocl_sh_bvalid = sh_ocl_bus.bvalid;
assign ocl_sh_bresp = sh_ocl_bus.bresp;
assign sh_ocl_bus.bready = sh_ocl_bready;

assign sh_ocl_bus.arvalid = sh_ocl_arvalid;
assign sh_ocl_bus.araddr = sh_ocl_araddr;
assign ocl_sh_arready = sh_ocl_bus.arready;

assign ocl_sh_rvalid = sh_ocl_bus.rvalid;
assign ocl_sh_rresp = sh_ocl_bus.rresp;
assign ocl_sh_rdata = sh_ocl_bus.rdata;
assign sh_ocl_bus.rready = sh_ocl_rready;

wire[31:0] start_addr;
wire[31:0] burst_len;
wire[31:0] write_val;

reg_file REG_FILE(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.axi_bus(sh_ocl_bus),
	.start_addr(start_addr),
	.burst_len(burst_len),
	.write_val(write_val)
);

// DRAM
axi4_bus_t dma_pcis_bus();
axi4_bus_t mem_ctrl_bus();
axi4_bus_t ddr_a_bus();
axi4_bus_t ddr_b_bus();
axi4_bus_t ddr_c_bus();
axi4_bus_t ddr_d_bus();

assign dma_pcis_bus.awid[5:0] = sh_cl_dma_pcis_awid;
assign dma_pcis_bus.awaddr = sh_cl_dma_pcis_awaddr;
assign dma_pcis_bus.awlen = sh_cl_dma_pcis_awlen;
assign dma_pcis_bus.awsize = sh_cl_dma_pcis_awsize;
assign dma_pcis_bus.awvalid = sh_cl_dma_pcis_awvalid;
assign cl_sh_dma_pcis_awready = dma_pcis_bus.awready;

assign dma_pcis_bus.wdata = sh_cl_dma_pcis_wdata;
assign dma_pcis_bus.wstrb = sh_cl_dma_pcis_wstrb;
assign dma_pcis_bus.wlast = sh_cl_dma_pcis_wlast;
assign dma_pcis_bus.wvalid = sh_cl_dma_pcis_wvalid;
assign cl_sh_dma_pcis_wready = dma_pcis_bus.wready;

assign cl_sh_dma_pcis_bid = dma_pcis_bus.bid[5:0];
assign cl_sh_dma_pcis_bresp = dma_pcis_bus.bresp;
assign cl_sh_dma_pcis_bvalid = dma_pcis_bus.bvalid;
assign dma_pcis_bus.bready = sh_cl_dma_pcis_bready;

assign dma_pcis_bus.arid[5:0] = sh_cl_dma_pcis_arid;
assign dma_pcis_bus.araddr = sh_cl_dma_pcis_araddr;
assign dma_pcis_bus.arlen = sh_cl_dma_pcis_arlen;
assign dma_pcis_bus.arsize = sh_cl_dma_pcis_arsize;
assign dma_pcis_bus.arvalid = sh_cl_dma_pcis_arvalid;
assign cl_sh_dma_pcis_arready = dma_pcis_bus.arready; 

assign cl_sh_dma_pcis_rid = dma_pcis_bus.rid[5:0];
assign cl_sh_dma_pcis_rdata = dma_pcis_bus.rdata;
assign cl_sh_dma_pcis_rresp = dma_pcis_bus.rresp;
assign cl_sh_dma_pcis_rlast = dma_pcis_bus.rlast;
assign cl_sh_dma_pcis_rvalid = dma_pcis_bus.rvalid;
assign dma_pcis_bus.rready = sh_cl_dma_pcis_rready;

dram_interconnect DRAM_INTERCONNECT(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.dma_pcis_bus(dma_pcis_bus),
	.mem_ctrl_bus(mem_ctrl_bus),
	.ddr_a_bus(ddr_a_bus),
	.ddr_b_bus(ddr_b_bus),
	.ddr_c_bus(ddr_c_bus),
	.ddr_d_bus(ddr_d_bus)	
);

assign cl_sh_status_vled[15:2] = 14'b0;
mem_ctrl MEM_CTRL(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.rd_enable(sh_cl_status_vdip[0]),
	.wr_enable(sh_cl_status_vdip[1]),
	.rd_done(cl_sh_status_vled[0]),
	.wr_done(cl_sh_status_vled[1]),
	.start_addr(start_addr),
	.burst_len(burst_len),
	.write_val(write_val),	
	.axi(mem_ctrl_bus)
);


/*
mock_dram MOCK_DRAM_A(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.axi(ddr_a_bus)
);

mock_dram MOCK_DRAM_B(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.axi(ddr_b_bus)
);

mock_dram MOCK_DRAM_C(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.axi(ddr_c_bus)
);

mock_dram MOCK_DRAM_D(
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.axi(ddr_d_bus)
);
*/

// DDR C
assign cl_sh_ddr_awid = ddr_c_bus.awid;
assign cl_sh_ddr_awaddr = ddr_c_bus.awaddr;
assign cl_sh_ddr_awlen = ddr_c_bus.awlen;
assign cl_sh_ddr_awsize = ddr_c_bus.awsize;
assign cl_sh_ddr_awvalid = ddr_c_bus.awvalid;
assign ddr_c_bus.awready = sh_cl_ddr_awready;
assign cl_sh_ddr_wid = 16'b0;
assign cl_sh_ddr_wdata = ddr_c_bus.wdata;
assign cl_sh_ddr_wstrb = ddr_c_bus.wstrb;
assign cl_sh_ddr_wlast = ddr_c_bus.wlast;
assign cl_sh_ddr_wvalid = ddr_c_bus.wvalid;
assign ddr_c_bus.wready = sh_cl_ddr_wready;
assign ddr_c_bus.bid = sh_cl_ddr_bid;
assign ddr_c_bus.bresp = sh_cl_ddr_bresp;
assign ddr_c_bus.bvalid = sh_cl_ddr_bvalid;
assign cl_sh_ddr_bready = ddr_c_bus.bready;
assign cl_sh_ddr_arid = ddr_c_bus.arid;
assign cl_sh_ddr_araddr = ddr_c_bus.araddr;
assign cl_sh_ddr_arlen = ddr_c_bus.arlen;
assign cl_sh_ddr_arsize = ddr_c_bus.arsize;
assign cl_sh_ddr_arvalid = ddr_c_bus.arvalid;
assign ddr_c_bus.arready = sh_cl_ddr_arready;
assign ddr_c_bus.rid = sh_cl_ddr_rid;
assign ddr_c_bus.rresp = sh_cl_ddr_rresp;
assign ddr_c_bus.rvalid = sh_cl_ddr_rvalid;
assign ddr_c_bus.rdata = sh_cl_ddr_rdata;
assign ddr_c_bus.rlast = sh_cl_ddr_rlast;
assign cl_sh_ddr_rready = ddr_c_bus.rready;

// DDR A,B,D
logic[7:0] sh_ddr_stat_addr_q[2:0];
logic[2:0] sh_ddr_stat_wr_q;
logic[2:0] sh_ddr_stat_rd_q; 
logic[31:0] sh_ddr_stat_wdata_q[2:0];
logic[2:0] ddr_sh_stat_ack_q;
logic[31:0] ddr_sh_stat_rdata_q[2:0];
logic[7:0] ddr_sh_stat_int_q[2:0];

lib_pipe #(.WIDTH(1+1+8+32), .STAGES(8)) PIPE_DDR_STAT0 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
    .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
    .out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
);

lib_pipe #(.WIDTH(1+8+32), .STAGES(8)) PIPE_DDR_STAT_ACK0 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
    .in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
    .out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
);

lib_pipe #(.WIDTH(1+1+8+32), .STAGES(8)) PIPE_DDR_STAT1 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
	.out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
);

lib_pipe #(.WIDTH(1+8+32), .STAGES(8)) PIPE_DDR_STAT_ACK1 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
    .in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
    .out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
);

lib_pipe #(.WIDTH(1+1+8+32), .STAGES(8)) PIPE_DDR_STAT2 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
    .in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
   	.out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
);

lib_pipe #(.WIDTH(1+8+32), .STAGES(8)) PIPE_DDR_STAT_ACK2 (
	.clk(clk_main_a0),
	.rst_n(rst_main_n_sync),
	.in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
    .out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
); 

logic[15:0] cl_sh_ddr_awid_2d[2:0];
logic[63:0] cl_sh_ddr_awaddr_2d[2:0];
logic[7:0] cl_sh_ddr_awlen_2d[2:0];
logic[2:0] cl_sh_ddr_awsize_2d[2:0];
logic cl_sh_ddr_awvalid_2d [2:0];
logic[2:0] sh_cl_ddr_awready_2d;

logic[15:0] cl_sh_ddr_wid_2d[2:0];
logic[511:0] cl_sh_ddr_wdata_2d[2:0];
logic[63:0] cl_sh_ddr_wstrb_2d[2:0];
logic[2:0] cl_sh_ddr_wlast_2d;
logic[2:0] cl_sh_ddr_wvalid_2d;
logic[2:0] sh_cl_ddr_wready_2d;

logic[15:0] sh_cl_ddr_bid_2d[2:0];
logic[1:0] sh_cl_ddr_bresp_2d[2:0];
logic[2:0] sh_cl_ddr_bvalid_2d;
logic[2:0] cl_sh_ddr_bready_2d;

logic[15:0] cl_sh_ddr_arid_2d[2:0];
logic[63:0] cl_sh_ddr_araddr_2d[2:0];
logic[7:0] cl_sh_ddr_arlen_2d[2:0];
logic[2:0] cl_sh_ddr_arsize_2d[2:0];
logic[2:0] cl_sh_ddr_arvalid_2d;
logic[2:0] sh_cl_ddr_arready_2d;

logic[15:0] sh_cl_ddr_rid_2d[2:0];
logic[511:0] sh_cl_ddr_rdata_2d[2:0];
logic[1:0] sh_cl_ddr_rresp_2d[2:0];
logic[2:0] sh_cl_ddr_rlast_2d;
logic[2:0] sh_cl_ddr_rvalid_2d;
logic[2:0] cl_sh_ddr_rready_2d;

assign cl_sh_ddr_awid_2d = '{ddr_d_bus.awid, ddr_b_bus.awid, ddr_a_bus.awid};
assign cl_sh_ddr_awaddr_2d = '{ddr_d_bus.awaddr, ddr_b_bus.awaddr, ddr_a_bus.awaddr};
assign cl_sh_ddr_awlen_2d = '{ddr_d_bus.awlen, ddr_b_bus.awlen, ddr_a_bus.awlen};
assign cl_sh_ddr_awsize_2d = '{ddr_d_bus.awsize, ddr_b_bus.awsize, ddr_a_bus.awsize};
assign cl_sh_ddr_awvalid_2d = '{ddr_d_bus.awvalid, ddr_b_bus.awvalid, ddr_a_bus.awvalid};
assign {ddr_d_bus.awready, ddr_b_bus.awready, ddr_a_bus.awready} = sh_cl_ddr_awready_2d;

assign cl_sh_ddr_wid_2d = '{16'b0, 16'b0, 16'b0};
assign cl_sh_ddr_wdata_2d = '{ddr_d_bus.wdata, ddr_b_bus.wdata, ddr_a_bus.wdata};
assign cl_sh_ddr_wstrb_2d = '{ddr_d_bus.wstrb, ddr_b_bus.wstrb, ddr_a_bus.wstrb};
assign cl_sh_ddr_wlast_2d = {ddr_d_bus.wlast, ddr_b_bus.wlast, ddr_a_bus.wlast};
assign cl_sh_ddr_wvalid_2d = {ddr_d_bus.wvalid, ddr_b_bus.wvalid, ddr_a_bus.wvalid};
assign {ddr_d_bus.wready, ddr_b_bus.wready, ddr_a_bus.wready} = sh_cl_ddr_wready_2d;

assign {ddr_d_bus.bid, ddr_b_bus.bid, ddr_a_bus.bid} = {sh_cl_ddr_bid_2d[2], sh_cl_ddr_bid_2d[1], sh_cl_ddr_bid_2d[0]};
assign {ddr_d_bus.bresp, ddr_b_bus.bresp, ddr_a_bus.bresp} = {sh_cl_ddr_bresp_2d[2], sh_cl_ddr_bresp_2d[1], sh_cl_ddr_bresp_2d[0]};
assign {ddr_d_bus.bvalid, ddr_b_bus.bvalid, ddr_a_bus.bvalid} = sh_cl_ddr_bvalid_2d;
assign cl_sh_ddr_bready_2d = {ddr_d_bus.bready, ddr_b_bus.bready, ddr_a_bus.bready};

assign cl_sh_ddr_arid_2d = '{ddr_d_bus.arid, ddr_b_bus.arid, ddr_a_bus.arid};
assign cl_sh_ddr_araddr_2d = '{ddr_d_bus.araddr, ddr_b_bus.araddr, ddr_a_bus.araddr};
assign cl_sh_ddr_arlen_2d = '{ddr_d_bus.arlen, ddr_b_bus.arlen, ddr_a_bus.arlen};
assign cl_sh_ddr_arsize_2d = '{ddr_d_bus.arsize, ddr_b_bus.arsize, ddr_a_bus.arsize};
assign cl_sh_ddr_arvalid_2d = {ddr_d_bus.arvalid, ddr_b_bus.arvalid, ddr_a_bus.arvalid};
assign {ddr_d_bus.arready, ddr_b_bus.arready, ddr_a_bus.arready} = sh_cl_ddr_arready_2d;

assign {ddr_d_bus.rid, ddr_b_bus.rid, ddr_a_bus.rid} = {sh_cl_ddr_rid_2d[2], sh_cl_ddr_rid_2d[1], sh_cl_ddr_rid_2d[0]};
assign {ddr_d_bus.rresp, ddr_b_bus.rresp, ddr_a_bus.rresp} = {sh_cl_ddr_rresp_2d[2], sh_cl_ddr_rresp_2d[1], sh_cl_ddr_rresp_2d[0]};
assign {ddr_d_bus.rdata, ddr_b_bus.rdata, ddr_a_bus.rdata} = {sh_cl_ddr_rdata_2d[2], sh_cl_ddr_rdata_2d[1], sh_cl_ddr_rdata_2d[0]};
assign {ddr_d_bus.rlast, ddr_b_bus.rlast, ddr_a_bus.rlast} = sh_cl_ddr_rlast_2d;
assign {ddr_d_bus.rvalid, ddr_b_bus.rvalid, ddr_a_bus.rvalid} = sh_cl_ddr_rvalid_2d;
assign cl_sh_ddr_rready_2d = {ddr_d_bus.rready, ddr_b_bus.rready, ddr_a_bus.rready};



(* dont_touch = "true" *) logic sh_ddr_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SH_DDR_SLC_RST_N
(
	.clk(clk_main_a0),
	.rst_n(1'b1),
	.in_bus(rst_main_n_sync),
	.out_bus(sh_ddr_sync_rst_n)
);

sh_ddr #(
	.DDR_A_PRESENT(1),
	.DDR_B_PRESENT(1),
	.DDR_D_PRESENT(1)
) SH_DDR (
	.clk(clk_main_a0),
	.rst_n(sh_ddr_sync_rst_n),
	.stat_clk(clk_main_a0),
	.stat_rst_n(sh_ddr_sync_rst_n),
	// DDR A
	.CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
   	.CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
	.M_A_ACT_N(M_A_ACT_N),
	.M_A_MA(M_A_MA),
	.M_A_BA(M_A_BA),
	.M_A_BG(M_A_BG),
	.M_A_CKE(M_A_CKE),
	.M_A_ODT(M_A_ODT),
	.M_A_CS_N(M_A_CS_N),
	.M_A_CLK_DN(M_A_CLK_DN),
	.M_A_CLK_DP(M_A_CLK_DP),
	.M_A_PAR(M_A_PAR),
	.M_A_DQ(M_A_DQ),
	.M_A_ECC(M_A_ECC),
	.M_A_DQS_DP(M_A_DQS_DP),
	.M_A_DQS_DN(M_A_DQS_DN),
	.cl_RST_DIMM_A_N(cl_RST_DIMM_A_N),
	// DDR B
	.CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
	.CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
	.M_B_ACT_N(M_B_ACT_N),
	.M_B_MA(M_B_MA),
	.M_B_BA(M_B_BA),
	.M_B_BG(M_B_BG),
	.M_B_CKE(M_B_CKE),
	.M_B_ODT(M_B_ODT),
	.M_B_CS_N(M_B_CS_N),
	.M_B_CLK_DN(M_B_CLK_DN),
	.M_B_CLK_DP(M_B_CLK_DP),
	.M_B_PAR(M_B_PAR),
	.M_B_DQ(M_B_DQ),
	.M_B_ECC(M_B_ECC),
	.M_B_DQS_DP(M_B_DQS_DP),
	.M_B_DQS_DN(M_B_DQS_DN),
	.cl_RST_DIMM_B_N(cl_RST_DIMM_B_N),
	// DDR D
	.CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
	.CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
	.M_D_ACT_N(M_D_ACT_N),
	.M_D_MA(M_D_MA),
	.M_D_BA(M_D_BA),
	.M_D_BG(M_D_BG),
	.M_D_CKE(M_D_CKE),
	.M_D_ODT(M_D_ODT),
	.M_D_CS_N(M_D_CS_N),
	.M_D_CLK_DN(M_D_CLK_DN),
	.M_D_CLK_DP(M_D_CLK_DP),
	.M_D_PAR(M_D_PAR),
	.M_D_DQ(M_D_DQ),
	.M_D_ECC(M_D_ECC),
	.M_D_DQS_DP(M_D_DQS_DP),
	.M_D_DQS_DN(M_D_DQS_DN),
	.cl_RST_DIMM_D_N(cl_RST_DIMM_D_N),
	// DMA
	.cl_sh_ddr_awid(cl_sh_ddr_awid_2d),
	.cl_sh_ddr_awaddr(cl_sh_ddr_awaddr_2d),
	.cl_sh_ddr_awlen(cl_sh_ddr_awlen_2d),
	.cl_sh_ddr_awsize(cl_sh_ddr_awsize_2d),
	.cl_sh_ddr_awvalid(cl_sh_ddr_awvalid_2d),
	.sh_cl_ddr_awready(sh_cl_ddr_awready_2d),

	.cl_sh_ddr_wid(cl_sh_ddr_wid_2d),
	.cl_sh_ddr_wdata(cl_sh_ddr_wdata_2d),
	.cl_sh_ddr_wstrb(cl_sh_ddr_wstrb_2d),
	.cl_sh_ddr_wlast(cl_sh_ddr_wlast_2d),
	.cl_sh_ddr_wvalid(cl_sh_ddr_wvalid_2d),
	.sh_cl_ddr_wready(sh_cl_ddr_wready_2d),

	.sh_cl_ddr_bid(sh_cl_ddr_bid_2d),
	.sh_cl_ddr_bresp(sh_cl_ddr_bresp_2d),
	.sh_cl_ddr_bvalid(sh_cl_ddr_bvalid_2d),
	.cl_sh_ddr_bready(cl_sh_ddr_bready_2d),

	.cl_sh_ddr_arid(cl_sh_ddr_arid_2d),
	.cl_sh_ddr_araddr(cl_sh_ddr_araddr_2d),
	.cl_sh_ddr_arlen(cl_sh_ddr_arlen_2d),
	.cl_sh_ddr_arsize(cl_sh_ddr_arsize_2d),
	.cl_sh_ddr_arvalid(cl_sh_ddr_arvalid_2d),
	.sh_cl_ddr_arready(sh_cl_ddr_arready_2d),

	.sh_cl_ddr_rid(sh_cl_ddr_rid_2d),
	.sh_cl_ddr_rdata(sh_cl_ddr_rdata_2d),
	.sh_cl_ddr_rresp(sh_cl_ddr_rresp_2d),
	.sh_cl_ddr_rlast(sh_cl_ddr_rlast_2d),
	.sh_cl_ddr_rvalid(sh_cl_ddr_rvalid_2d),
	.cl_sh_ddr_rready(cl_sh_ddr_rready_2d),

	.sh_cl_ddr_is_ready(),

	// ddr stat
	.sh_ddr_stat_addr0(sh_ddr_stat_addr_q[0]),
	.sh_ddr_stat_wr0(sh_ddr_stat_wr_q[0]), 
	.sh_ddr_stat_rd0(sh_ddr_stat_rd_q[0]), 
	.sh_ddr_stat_wdata0(sh_ddr_stat_wdata_q[0]), 
	.ddr_sh_stat_ack0(ddr_sh_stat_ack_q[0]),
	.ddr_sh_stat_rdata0(ddr_sh_stat_rdata_q[0]),
	.ddr_sh_stat_int0(ddr_sh_stat_int_q[0]),

	.sh_ddr_stat_addr1(sh_ddr_stat_addr_q[1]),
	.sh_ddr_stat_wr1(sh_ddr_stat_wr_q[1]), 
	.sh_ddr_stat_rd1(sh_ddr_stat_rd_q[1]), 
	.sh_ddr_stat_wdata1(sh_ddr_stat_wdata_q[1]), 
	.ddr_sh_stat_ack1(ddr_sh_stat_ack_q[1]),
	.ddr_sh_stat_rdata1(ddr_sh_stat_rdata_q[1]),
	.ddr_sh_stat_int1(ddr_sh_stat_int_q[1]),

	.sh_ddr_stat_addr2(sh_ddr_stat_addr_q[2]),
	.sh_ddr_stat_wr2(sh_ddr_stat_wr_q[2]), 
	.sh_ddr_stat_rd2(sh_ddr_stat_rd_q[2]), 
	.sh_ddr_stat_wdata2(sh_ddr_stat_wdata_q[2]), 
	.ddr_sh_stat_ack2(ddr_sh_stat_ack_q[2]),
	.ddr_sh_stat_rdata2(ddr_sh_stat_rdata_q[2]),
	.ddr_sh_stat_int2(ddr_sh_stat_int_q[2]) 
);



endmodule






/**
 *	dram_interconnect.sv
 *	DRAM interconnect that is driven by dual-masters, controlling 4 banks of DRAM by AXI-4 interface.
 *
 *	@author: Tommy Jung
 */

module dram_interconnect
(
	input clk,
	input rst_n,
	axi4_bus_t.master dma_pcis_bus,
	axi4_bus_t.master mem_ctrl_bus,
	axi4_bus_t.slave ddr_a_bus,
	axi4_bus_t.slave ddr_b_bus,
	axi4_bus_t.slave ddr_c_bus,
	axi4_bus_t.slave ddr_d_bus
);

axi4_bus_t dma_pcis_bus_q();
axi4_bus_t src_a_bus();
axi4_bus_t src_b_bus();
axi4_bus_t src_c_bus();
axi4_bus_t src_d_bus();
axi4_bus_t dst_a_bus();
axi4_bus_t dst_b_bus();
axi4_bus_t dst_d_bus();

(* dont_touch = "true" *) logic slr0_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_n), .out_bus(slr0_rst_n));
(* dont_touch = "true" *) logic slr1_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR1_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_n), .out_bus(slr1_rst_n));
(* dont_touch = "true" *) logic slr2_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR2_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_n), .out_bus(slr2_rst_n));

axi_register_slice DMA_PCIS_REG_SLICE(
	.aclk(clk),
	.aresetn(slr0_rst_n),
	.s_axi_awid    (dma_pcis_bus.awid),
	.s_axi_awaddr  (dma_pcis_bus.awaddr),
	.s_axi_awlen   (dma_pcis_bus.awlen),
    .s_axi_awvalid (dma_pcis_bus.awvalid),
    .s_axi_awsize  (dma_pcis_bus.awsize),
    .s_axi_awready (dma_pcis_bus.awready),
    .s_axi_wdata   (dma_pcis_bus.wdata),
    .s_axi_wstrb   (dma_pcis_bus.wstrb),
    .s_axi_wlast   (dma_pcis_bus.wlast),
    .s_axi_wvalid  (dma_pcis_bus.wvalid),
    .s_axi_wready  (dma_pcis_bus.wready),
    .s_axi_bid     (dma_pcis_bus.bid),
    .s_axi_bresp   (dma_pcis_bus.bresp),
    .s_axi_bvalid  (dma_pcis_bus.bvalid),
    .s_axi_bready  (dma_pcis_bus.bready),
    .s_axi_arid    (dma_pcis_bus.arid),
    .s_axi_araddr  (dma_pcis_bus.araddr),
    .s_axi_arlen   (dma_pcis_bus.arlen),
    .s_axi_arvalid (dma_pcis_bus.arvalid),
    .s_axi_arsize  (dma_pcis_bus.arsize),
    .s_axi_arready (dma_pcis_bus.arready),
    .s_axi_rid     (dma_pcis_bus.rid),
    .s_axi_rdata   (dma_pcis_bus.rdata),
    .s_axi_rresp   (dma_pcis_bus.rresp),
    .s_axi_rlast   (dma_pcis_bus.rlast),
    .s_axi_rvalid  (dma_pcis_bus.rvalid),
    .s_axi_rready  (dma_pcis_bus.rready),
    .m_axi_awid    (dma_pcis_bus_q.awid),
    .m_axi_awaddr  (dma_pcis_bus_q.awaddr),
    .m_axi_awlen   (dma_pcis_bus_q.awlen),
    .m_axi_awvalid (dma_pcis_bus_q.awvalid),
    .m_axi_awsize  (dma_pcis_bus_q.awsize),
	.m_axi_awready (dma_pcis_bus_q.awready),
	.m_axi_wdata   (dma_pcis_bus_q.wdata),
	.m_axi_wstrb   (dma_pcis_bus_q.wstrb),
	.m_axi_wvalid  (dma_pcis_bus_q.wvalid),
	.m_axi_wlast   (dma_pcis_bus_q.wlast),
	.m_axi_wready  (dma_pcis_bus_q.wready),
	.m_axi_bresp   (dma_pcis_bus_q.bresp),
	.m_axi_bvalid  (dma_pcis_bus_q.bvalid),
	.m_axi_bid     (dma_pcis_bus_q.bid),
	.m_axi_bready  (dma_pcis_bus_q.bready),
	.m_axi_arid    (dma_pcis_bus_q.arid),
	.m_axi_araddr  (dma_pcis_bus_q.araddr),
	.m_axi_arlen   (dma_pcis_bus_q.arlen),
	.m_axi_arsize  (dma_pcis_bus_q.arsize),
	.m_axi_arvalid (dma_pcis_bus_q.arvalid),
	.m_axi_arready (dma_pcis_bus_q.arready),
	.m_axi_rid     (dma_pcis_bus_q.rid),
	.m_axi_rdata   (dma_pcis_bus_q.rdata),
	.m_axi_rresp   (dma_pcis_bus_q.rresp),
	.m_axi_rlast   (dma_pcis_bus_q.rlast),
	.m_axi_rvalid  (dma_pcis_bus_q.rvalid),
	.m_axi_rready  (dma_pcis_bus_q.rready)
);

(* dont_touch = "true" *)
cl_axi_interconnect AXI_CROSSBAR
(
	.ACLK(clk),
	.ARESETN(slr1_rst_n),

	.M00_AXI_araddr(src_a_bus.araddr),
    .M00_AXI_arburst(),
    .M00_AXI_arcache(),
    .M00_AXI_arid(src_a_bus.arid[6:0]),
    .M00_AXI_arlen(src_a_bus.arlen),
    .M00_AXI_arlock(),
    .M00_AXI_arprot(),
    .M00_AXI_arqos(),
    .M00_AXI_arready(src_a_bus.arready),
    .M00_AXI_arregion(),
    .M00_AXI_arsize(src_a_bus.arsize),
    .M00_AXI_arvalid(src_a_bus.arvalid),
    .M00_AXI_awaddr(src_a_bus.awaddr),
    .M00_AXI_awburst(),
    .M00_AXI_awcache(),
    .M00_AXI_awid(src_a_bus.awid[6:0]),
    .M00_AXI_awlen(src_a_bus.awlen),
    .M00_AXI_awlock(),
    .M00_AXI_awprot(),
    .M00_AXI_awqos(),
    .M00_AXI_awready(src_a_bus.awready),
    .M00_AXI_awregion(),
    .M00_AXI_awsize(src_a_bus.awsize),
    .M00_AXI_awvalid(src_a_bus.awvalid),
    .M00_AXI_bid(src_a_bus.bid[6:0]),
    .M00_AXI_bready(src_a_bus.bready),
    .M00_AXI_bresp(src_a_bus.bresp),
    .M00_AXI_bvalid(src_a_bus.bvalid),
    .M00_AXI_rdata(src_a_bus.rdata),
    .M00_AXI_rid(src_a_bus.rid[6:0]),
    .M00_AXI_rlast(src_a_bus.rlast),
    .M00_AXI_rready(src_a_bus.rready),
    .M00_AXI_rresp(src_a_bus.rresp),
    .M00_AXI_rvalid(src_a_bus.rvalid),
    .M00_AXI_wdata(src_a_bus.wdata),
    .M00_AXI_wlast(src_a_bus.wlast),
    .M00_AXI_wready(src_a_bus.wready),
    .M00_AXI_wstrb(src_a_bus.wstrb),
    .M00_AXI_wvalid(src_a_bus.wvalid),	

	.M01_AXI_araddr(src_b_bus.araddr),
    .M01_AXI_arburst(),
    .M01_AXI_arcache(),
    .M01_AXI_arid(src_b_bus.arid[6:0]),
    .M01_AXI_arlen(src_b_bus.arlen),
    .M01_AXI_arlock(),
    .M01_AXI_arprot(),
    .M01_AXI_arqos(),
    .M01_AXI_arready(src_b_bus.arready),
    .M01_AXI_arregion(),
    .M01_AXI_arsize(src_b_bus.arsize),
    .M01_AXI_arvalid(src_b_bus.arvalid),
    .M01_AXI_awaddr(src_b_bus.awaddr),
    .M01_AXI_awburst(),
    .M01_AXI_awcache(),
    .M01_AXI_awid(src_b_bus.awid[6:0]),
    .M01_AXI_awlen(src_b_bus.awlen),
    .M01_AXI_awlock(),
    .M01_AXI_awprot(),
    .M01_AXI_awqos(),
    .M01_AXI_awready(src_b_bus.awready),
    .M01_AXI_awregion(),
    .M01_AXI_awsize(src_b_bus.awsize),
    .M01_AXI_awvalid(src_b_bus.awvalid),
    .M01_AXI_bid(src_b_bus.bid[6:0]),
    .M01_AXI_bready(src_b_bus.bready),
    .M01_AXI_bresp(src_b_bus.bresp),
    .M01_AXI_bvalid(src_b_bus.bvalid),
    .M01_AXI_rdata(src_b_bus.rdata),
    .M01_AXI_rid(src_b_bus.rid[6:0]),
    .M01_AXI_rlast(src_b_bus.rlast),
    .M01_AXI_rready(src_b_bus.rready),
    .M01_AXI_rresp(src_b_bus.rresp),
    .M01_AXI_rvalid(src_b_bus.rvalid),
    .M01_AXI_wdata(src_b_bus.wdata),
    .M01_AXI_wlast(src_b_bus.wlast),
    .M01_AXI_wready(src_b_bus.wready),
    .M01_AXI_wstrb(src_b_bus.wstrb),
    .M01_AXI_wvalid(src_b_bus.wvalid),

	.M02_AXI_araddr(src_c_bus.araddr),
    .M02_AXI_arburst(),
    .M02_AXI_arcache(),
    .M02_AXI_arid(src_c_bus.arid[6:0]),
    .M02_AXI_arlen(src_c_bus.arlen),
    .M02_AXI_arlock(),
    .M02_AXI_arprot(),
    .M02_AXI_arqos(),
    .M02_AXI_arready(src_c_bus.arready),
    .M02_AXI_arregion(),
    .M02_AXI_arsize(src_c_bus.arsize),
    .M02_AXI_arvalid(src_c_bus.arvalid),
    .M02_AXI_awaddr(src_c_bus.awaddr),
    .M02_AXI_awburst(),
    .M02_AXI_awcache(),
    .M02_AXI_awid(src_c_bus.awid[6:0]),
    .M02_AXI_awlen(src_c_bus.awlen),
    .M02_AXI_awlock(),
    .M02_AXI_awprot(),
    .M02_AXI_awqos(),
    .M02_AXI_awready(src_c_bus.awready),
    .M02_AXI_awregion(),
    .M02_AXI_awsize(src_c_bus.awsize),
    .M02_AXI_awvalid(src_c_bus.awvalid),
    .M02_AXI_bid(src_c_bus.bid[6:0]),
    .M02_AXI_bready(src_c_bus.bready),
    .M02_AXI_bresp(src_c_bus.bresp),
    .M02_AXI_bvalid(src_c_bus.bvalid),
    .M02_AXI_rdata(src_c_bus.rdata),
    .M02_AXI_rid(src_c_bus.rid[6:0]),
    .M02_AXI_rlast(src_c_bus.rlast),
    .M02_AXI_rready(src_c_bus.rready),
    .M02_AXI_rresp(src_c_bus.rresp),
    .M02_AXI_rvalid(src_c_bus.rvalid),
    .M02_AXI_wdata(src_c_bus.wdata),
    .M02_AXI_wlast(src_c_bus.wlast),
    .M02_AXI_wready(src_c_bus.wready),
    .M02_AXI_wstrb(src_c_bus.wstrb),
    .M02_AXI_wvalid(src_c_bus.wvalid),

	.M03_AXI_araddr(src_d_bus.araddr),
    .M03_AXI_arburst(),
    .M03_AXI_arcache(),
    .M03_AXI_arid(src_d_bus.arid[6:0]),
    .M03_AXI_arlen(src_d_bus.arlen),
    .M03_AXI_arlock(),
    .M03_AXI_arprot(),
    .M03_AXI_arqos(),
    .M03_AXI_arready(src_d_bus.arready),
    .M03_AXI_arregion(),
    .M03_AXI_arsize(src_d_bus.arsize),
    .M03_AXI_arvalid(src_d_bus.arvalid),
    .M03_AXI_awaddr(src_d_bus.awaddr),
    .M03_AXI_awburst(),
    .M03_AXI_awcache(),
    .M03_AXI_awid(src_d_bus.awid[6:0]),
    .M03_AXI_awlen(src_d_bus.awlen),
    .M03_AXI_awlock(),
    .M03_AXI_awprot(),
    .M03_AXI_awqos(),
    .M03_AXI_awready(src_d_bus.awready),
    .M03_AXI_awregion(),
    .M03_AXI_awsize(src_d_bus.awsize),
    .M03_AXI_awvalid(src_d_bus.awvalid),
    .M03_AXI_bid(src_d_bus.bid[6:0]),
    .M03_AXI_bready(src_d_bus.bready),
    .M03_AXI_bresp(src_d_bus.bresp),
    .M03_AXI_bvalid(src_d_bus.bvalid),
    .M03_AXI_rdata(src_d_bus.rdata),
    .M03_AXI_rid(src_d_bus.rid[6:0]),
    .M03_AXI_rlast(src_d_bus.rlast),
    .M03_AXI_rready(src_d_bus.rready),
    .M03_AXI_rresp(src_d_bus.rresp),
    .M03_AXI_rvalid(src_d_bus.rvalid),
    .M03_AXI_wdata(src_d_bus.wdata),
    .M03_AXI_wlast(src_d_bus.wlast),
    .M03_AXI_wready(src_d_bus.wready),
    .M03_AXI_wstrb(src_d_bus.wstrb),
    .M03_AXI_wvalid(src_d_bus.wvalid),

	.S00_AXI_araddr({dma_pcis_bus_q.araddr[63:37], 1'b0, dma_pcis_bus_q.araddr[35:0]}),
    .S00_AXI_arburst(2'b1),
    .S00_AXI_arcache(4'b11),
    .S00_AXI_arid(dma_pcis_bus_q.arid[5:0]),
    .S00_AXI_arlen(dma_pcis_bus_q.arlen),
    .S00_AXI_arlock(1'b0),
    .S00_AXI_arprot(3'b10),
    .S00_AXI_arqos(4'b0),
    .S00_AXI_arready(dma_pcis_bus_q.arready),
    .S00_AXI_arregion(4'b0),
    .S00_AXI_arsize(dma_pcis_bus_q.arsize),
    .S00_AXI_arvalid(dma_pcis_bus_q.arvalid),
    .S00_AXI_awaddr({dma_pcis_bus_q.awaddr[63:37], 1'b0, dma_pcis_bus_q.awaddr[35:0]}),
    .S00_AXI_awburst(2'b1),
    .S00_AXI_awcache(4'b11),
    .S00_AXI_awid(dma_pcis_bus_q.awid[5:0]),
    .S00_AXI_awlen(dma_pcis_bus_q.awlen),
    .S00_AXI_awlock(1'b0),
    .S00_AXI_awprot(3'b10),
    .S00_AXI_awqos(4'b0),
    .S00_AXI_awready(dma_pcis_bus_q.awready),
    .S00_AXI_awregion(4'b0),
    .S00_AXI_awsize(dma_pcis_bus_q.awsize),
    .S00_AXI_awvalid(dma_pcis_bus_q.awvalid),
    .S00_AXI_bid(dma_pcis_bus_q.bid[5:0]),
    .S00_AXI_bready(dma_pcis_bus_q.bready),
    .S00_AXI_bresp(dma_pcis_bus_q.bresp),
    .S00_AXI_bvalid(dma_pcis_bus_q.bvalid),
    .S00_AXI_rdata(dma_pcis_bus_q.rdata),
    .S00_AXI_rid(dma_pcis_bus_q.rid[5:0]),
    .S00_AXI_rlast(dma_pcis_bus_q.rlast),
    .S00_AXI_rready(dma_pcis_bus_q.rready),
    .S00_AXI_rresp(dma_pcis_bus_q.rresp),
    .S00_AXI_rvalid(dma_pcis_bus_q.rvalid),
    .S00_AXI_wdata(dma_pcis_bus_q.wdata),
    .S00_AXI_wlast(dma_pcis_bus_q.wlast),
    .S00_AXI_wready(dma_pcis_bus_q.wready),
    .S00_AXI_wstrb(dma_pcis_bus_q.wstrb),
    .S00_AXI_wvalid(dma_pcis_bus_q.wvalid),

	.S01_AXI_araddr(mem_ctrl_bus.araddr),
    .S01_AXI_arburst(2'b1),
    .S01_AXI_arcache(4'b11),
    .S01_AXI_arid(mem_ctrl_bus.arid[5:0]),
    .S01_AXI_arlen(mem_ctrl_bus.arlen),
    .S01_AXI_arlock(1'b0),
    .S01_AXI_arprot(3'b10),
    .S01_AXI_arqos(4'b0),
    .S01_AXI_arready(mem_ctrl_bus.arready),
    .S01_AXI_arregion(4'b0),
    .S01_AXI_arsize(mem_ctrl_bus.arsize),
    .S01_AXI_arvalid(mem_ctrl_bus.arvalid),
    .S01_AXI_awaddr(mem_ctrl_bus.awaddr),
    .S01_AXI_awburst(2'b1),
    .S01_AXI_awcache(4'b11),
    .S01_AXI_awid(mem_ctrl_bus.awid[5:0]),
    .S01_AXI_awlen(mem_ctrl_bus.awlen),
    .S01_AXI_awlock(1'b0),
    .S01_AXI_awprot(3'b10),
    .S01_AXI_awqos(4'b0),
    .S01_AXI_awready(mem_ctrl_bus.awready),
    .S01_AXI_awregion(4'b0),
    .S01_AXI_awsize(mem_ctrl_bus.awsize),
    .S01_AXI_awvalid(mem_ctrl_bus.awvalid),
    .S01_AXI_bid(mem_ctrl_bus.bid[5:0]),
    .S01_AXI_bready(mem_ctrl_bus.bready),
    .S01_AXI_bresp(mem_ctrl_bus.bresp),
    .S01_AXI_bvalid(mem_ctrl_bus.bvalid),
    .S01_AXI_rdata(mem_ctrl_bus.rdata),
    .S01_AXI_rid(mem_ctrl_bus.rid[5:0]),
    .S01_AXI_rlast(mem_ctrl_bus.rlast),
    .S01_AXI_rready(mem_ctrl_bus.rready),
    .S01_AXI_rresp(mem_ctrl_bus.rresp),
    .S01_AXI_rvalid(mem_ctrl_bus.rvalid),
    .S01_AXI_wdata(mem_ctrl_bus.wdata),
    .S01_AXI_wlast(mem_ctrl_bus.wlast),
    .S01_AXI_wready(mem_ctrl_bus.wready),
    .S01_AXI_wstrb(mem_ctrl_bus.wstrb),
    .S01_AXI_wvalid(mem_ctrl_bus.wvalid)
);

// DDR A
src_register_slice DDR_A_TST_AXI4_REG_SLC_1 (
	.aclk           (clk),
    .aresetn        (slr1_rst_n),
    .s_axi_awid     (src_a_bus.awid),
	.s_axi_awaddr   ({src_a_bus.awaddr[63:36], 2'b0, src_a_bus.awaddr[33:0]}),
	.s_axi_awlen    (src_a_bus.awlen),
	.s_axi_awsize   (src_a_bus.awsize),
	.s_axi_awburst  (2'b1),
	.s_axi_awlock   (1'b0),
	.s_axi_awcache  (4'b11),
	.s_axi_awprot   (3'b10),
	.s_axi_awregion (4'b0),
	.s_axi_awqos    (4'b0),
	.s_axi_awvalid  (src_a_bus.awvalid),
	.s_axi_awready  (src_a_bus.awready),
	.s_axi_wdata    (src_a_bus.wdata),
	.s_axi_wstrb    (src_a_bus.wstrb),
	.s_axi_wlast    (src_a_bus.wlast),
	.s_axi_wvalid   (src_a_bus.wvalid),
	.s_axi_wready   (src_a_bus.wready),
	.s_axi_bid      (src_a_bus.bid),
	.s_axi_bresp    (src_a_bus.bresp),
	.s_axi_bvalid   (src_a_bus.bvalid),
	.s_axi_bready   (src_a_bus.bready),
	.s_axi_arid     (src_a_bus.arid),
	.s_axi_araddr   ({src_a_bus.araddr[63:36], 2'b0, src_a_bus.araddr[33:0]}),
	.s_axi_arlen    (src_a_bus.arlen),
	.s_axi_arsize   (src_a_bus.arsize),
	.s_axi_arburst  (2'b1),
	.s_axi_arlock   (1'b0),
	.s_axi_arcache  (4'b11),
	.s_axi_arprot   (3'b10),
	.s_axi_arregion (4'b0),
	.s_axi_arqos    (4'b0),
	.s_axi_arvalid  (src_a_bus.arvalid),
	.s_axi_arready  (src_a_bus.arready),
	.s_axi_rid      (src_a_bus.rid),
	.s_axi_rdata    (src_a_bus.rdata),
	.s_axi_rresp    (src_a_bus.rresp),
	.s_axi_rlast    (src_a_bus.rlast),
	.s_axi_rvalid   (src_a_bus.rvalid),
	.s_axi_rready   (src_a_bus.rready),  
	.m_axi_awid     (dst_a_bus.awid),   
	.m_axi_awaddr   (dst_a_bus.awaddr), 
	.m_axi_awlen    (dst_a_bus.awlen),
	.m_axi_awsize   (dst_a_bus.awsize),
	.m_axi_awburst  (),
	.m_axi_awlock   (),
	.m_axi_awcache  (),
	.m_axi_awprot   (),
	.m_axi_awregion (),
	.m_axi_awqos    (),  
	.m_axi_awvalid  (dst_a_bus.awvalid),
	.m_axi_awready  (dst_a_bus.awready),
	.m_axi_wdata    (dst_a_bus.wdata),  
	.m_axi_wstrb    (dst_a_bus.wstrb),  
	.m_axi_wlast    (dst_a_bus.wlast),  
	.m_axi_wvalid   (dst_a_bus.wvalid), 
	.m_axi_wready   (dst_a_bus.wready), 
	.m_axi_bid      (dst_a_bus.bid),    
	.m_axi_bresp    (dst_a_bus.bresp),  
	.m_axi_bvalid   (dst_a_bus.bvalid), 
	.m_axi_bready   (dst_a_bus.bready), 
	.m_axi_arid     (dst_a_bus.arid),   
	.m_axi_araddr   (dst_a_bus.araddr), 
	.m_axi_arlen    (dst_a_bus.arlen),  
	.m_axi_arsize   (dst_a_bus.arsize),
	.m_axi_arburst  (),
	.m_axi_arlock   (),
	.m_axi_arcache  (),
	.m_axi_arprot   (),
	.m_axi_arregion (),
	.m_axi_arqos    (), 
	.m_axi_arvalid  (dst_a_bus.arvalid),
	.m_axi_arready  (dst_a_bus.arready),
	.m_axi_rid      (dst_a_bus.rid),    
	.m_axi_rdata    (dst_a_bus.rdata),  
	.m_axi_rresp    (dst_a_bus.rresp),  
	.m_axi_rlast    (dst_a_bus.rlast),  
	.m_axi_rvalid   (dst_a_bus.rvalid), 
	.m_axi_rready   (dst_a_bus.rready)
);

dest_register_slice DDR_A_TST_AXI4_REG_SLC_2 (
       .aclk           (clk),
       .aresetn        (slr2_rst_n),
       .s_axi_awid     (dst_a_bus.awid),
       .s_axi_awaddr   (dst_a_bus.awaddr),
       .s_axi_awlen    (dst_a_bus.awlen),
       .s_axi_awsize   (dst_a_bus.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (dst_a_bus.awvalid),
       .s_axi_awready  (dst_a_bus.awready),
       .s_axi_wdata    (dst_a_bus.wdata),
       .s_axi_wstrb    (dst_a_bus.wstrb),
       .s_axi_wlast    (dst_a_bus.wlast),
       .s_axi_wvalid   (dst_a_bus.wvalid),
       .s_axi_wready   (dst_a_bus.wready),
       .s_axi_bid      (dst_a_bus.bid),
       .s_axi_bresp    (dst_a_bus.bresp),
       .s_axi_bvalid   (dst_a_bus.bvalid),
       .s_axi_bready   (dst_a_bus.bready),
       .s_axi_arid     (dst_a_bus.arid),
       .s_axi_araddr   (dst_a_bus.araddr),
       .s_axi_arlen    (dst_a_bus.arlen),
       .s_axi_arsize   (dst_a_bus.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (dst_a_bus.arvalid),
       .s_axi_arready  (dst_a_bus.arready),
       .s_axi_rid      (dst_a_bus.rid),
       .s_axi_rdata    (dst_a_bus.rdata),
       .s_axi_rresp    (dst_a_bus.rresp),
       .s_axi_rlast    (dst_a_bus.rlast),
       .s_axi_rvalid   (dst_a_bus.rvalid),
       .s_axi_rready   (dst_a_bus.rready),  
       .m_axi_awid     (ddr_a_bus.awid[6:0]),   
       .m_axi_awaddr   (ddr_a_bus.awaddr), 
       .m_axi_awlen    (ddr_a_bus.awlen),
       .m_axi_awsize   (ddr_a_bus.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),   
       .m_axi_awvalid  (ddr_a_bus.awvalid),
       .m_axi_awready  (ddr_a_bus.awready),
       .m_axi_wdata    (ddr_a_bus.wdata),  
       .m_axi_wstrb    (ddr_a_bus.wstrb),  
       .m_axi_wlast    (ddr_a_bus.wlast),  
       .m_axi_wvalid   (ddr_a_bus.wvalid), 
       .m_axi_wready   (ddr_a_bus.wready), 
       .m_axi_bid      (ddr_a_bus.bid),    
       .m_axi_bresp    (ddr_a_bus.bresp),  
       .m_axi_bvalid   (ddr_a_bus.bvalid), 
       .m_axi_bready   (ddr_a_bus.bready), 
       .m_axi_arid     (ddr_a_bus.arid[6:0]),   
       .m_axi_araddr   (ddr_a_bus.araddr), 
       .m_axi_arlen    (ddr_a_bus.arlen),
       .m_axi_arsize   (ddr_a_bus.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),   
       .m_axi_arvalid  (ddr_a_bus.arvalid),
       .m_axi_arready  (ddr_a_bus.arready),
       .m_axi_rid      (ddr_a_bus.rid),    
       .m_axi_rdata    (ddr_a_bus.rdata),  
       .m_axi_rresp    (ddr_a_bus.rresp),  
       .m_axi_rlast    (ddr_a_bus.rlast),  
       .m_axi_rvalid   (ddr_a_bus.rvalid), 
       .m_axi_rready   (ddr_a_bus.rready)
);

assign ddr_a_bus.awid[15:7] = 9'b0;
assign ddr_a_bus.arid[15:7] = 9'b0;

// DDR B
src_register_slice DDR_B_TST_AXI4_REG_SLC_1 (
	.aclk           (clk),
    .aresetn        (slr1_rst_n),
    .s_axi_awid     (src_b_bus.awid),
	.s_axi_awaddr   ({src_b_bus.awaddr[63:36], 2'b0, src_b_bus.awaddr[33:0]}),
	.s_axi_awlen    (src_b_bus.awlen),
	.s_axi_awsize   (src_b_bus.awsize),
	.s_axi_awburst  (2'b1),
	.s_axi_awlock   (1'b0),
	.s_axi_awcache  (4'b11),
	.s_axi_awprot   (3'b10),
	.s_axi_awregion (4'b0),
	.s_axi_awqos    (4'b0),
	.s_axi_awvalid  (src_b_bus.awvalid),
	.s_axi_awready  (src_b_bus.awready),
	.s_axi_wdata    (src_b_bus.wdata),
	.s_axi_wstrb    (src_b_bus.wstrb),
	.s_axi_wlast    (src_b_bus.wlast),
	.s_axi_wvalid   (src_b_bus.wvalid),
	.s_axi_wready   (src_b_bus.wready),
	.s_axi_bid      (src_b_bus.bid),
	.s_axi_bresp    (src_b_bus.bresp),
	.s_axi_bvalid   (src_b_bus.bvalid),
	.s_axi_bready   (src_b_bus.bready),
	.s_axi_arid     (src_b_bus.arid),
	.s_axi_araddr   ({src_b_bus.araddr[63:36], 2'b0, src_b_bus.araddr[33:0]}),
	.s_axi_arlen    (src_b_bus.arlen),
	.s_axi_arsize   (src_b_bus.arsize),
	.s_axi_arburst  (2'b1),
	.s_axi_arlock   (1'b0),
	.s_axi_arcache  (4'b11),
	.s_axi_arprot   (3'b10),
	.s_axi_arregion (4'b0),
	.s_axi_arqos    (4'b0),
	.s_axi_arvalid  (src_b_bus.arvalid),
	.s_axi_arready  (src_b_bus.arready),
	.s_axi_rid      (src_b_bus.rid),
	.s_axi_rdata    (src_b_bus.rdata),
	.s_axi_rresp    (src_b_bus.rresp),
	.s_axi_rlast    (src_b_bus.rlast),
	.s_axi_rvalid   (src_b_bus.rvalid),
	.s_axi_rready   (src_b_bus.rready),  
	.m_axi_awid     (dst_b_bus.awid),   
	.m_axi_awaddr   (dst_b_bus.awaddr), 
	.m_axi_awlen    (dst_b_bus.awlen),
	.m_axi_awsize   (dst_b_bus.awsize),
	.m_axi_awburst  (),
	.m_axi_awlock   (),
	.m_axi_awcache  (),
	.m_axi_awprot   (),
	.m_axi_awregion (),
	.m_axi_awqos    (),  
	.m_axi_awvalid  (dst_b_bus.awvalid),
	.m_axi_awready  (dst_b_bus.awready),
	.m_axi_wdata    (dst_b_bus.wdata),  
	.m_axi_wstrb    (dst_b_bus.wstrb),  
	.m_axi_wlast    (dst_b_bus.wlast),  
	.m_axi_wvalid   (dst_b_bus.wvalid), 
	.m_axi_wready   (dst_b_bus.wready), 
	.m_axi_bid      (dst_b_bus.bid),    
	.m_axi_bresp    (dst_b_bus.bresp),  
	.m_axi_bvalid   (dst_b_bus.bvalid), 
	.m_axi_bready   (dst_b_bus.bready), 
	.m_axi_arid     (dst_b_bus.arid),   
	.m_axi_araddr   (dst_b_bus.araddr), 
	.m_axi_arlen    (dst_b_bus.arlen),  
	.m_axi_arsize   (dst_b_bus.arsize),
	.m_axi_arburst  (),
	.m_axi_arlock   (),
	.m_axi_arcache  (),
	.m_axi_arprot   (),
	.m_axi_arregion (),
	.m_axi_arqos    (), 
	.m_axi_arvalid  (dst_b_bus.arvalid),
	.m_axi_arready  (dst_b_bus.arready),
	.m_axi_rid      (dst_b_bus.rid),    
	.m_axi_rdata    (dst_b_bus.rdata),  
	.m_axi_rresp    (dst_b_bus.rresp),  
	.m_axi_rlast    (dst_b_bus.rlast),  
	.m_axi_rvalid   (dst_b_bus.rvalid), 
	.m_axi_rready   (dst_b_bus.rready)
);

dest_register_slice DDR_B_TST_AXI4_REG_SLC_2 (
       .aclk           (clk),
       .aresetn        (slr1_rst_n),
       .s_axi_awid     (dst_b_bus.awid),
       .s_axi_awaddr   (dst_b_bus.awaddr),
       .s_axi_awlen    (dst_b_bus.awlen),
       .s_axi_awsize   (dst_b_bus.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (dst_b_bus.awvalid),
       .s_axi_awready  (dst_b_bus.awready),
       .s_axi_wdata    (dst_b_bus.wdata),
       .s_axi_wstrb    (dst_b_bus.wstrb),
       .s_axi_wlast    (dst_b_bus.wlast),
       .s_axi_wvalid   (dst_b_bus.wvalid),
       .s_axi_wready   (dst_b_bus.wready),
       .s_axi_bid      (dst_b_bus.bid),
       .s_axi_bresp    (dst_b_bus.bresp),
       .s_axi_bvalid   (dst_b_bus.bvalid),
       .s_axi_bready   (dst_b_bus.bready),
       .s_axi_arid     (dst_b_bus.arid),
       .s_axi_araddr   (dst_b_bus.araddr),
       .s_axi_arlen    (dst_b_bus.arlen),
       .s_axi_arsize   (dst_b_bus.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (dst_b_bus.arvalid),
       .s_axi_arready  (dst_b_bus.arready),
       .s_axi_rid      (dst_b_bus.rid),
       .s_axi_rdata    (dst_b_bus.rdata),
       .s_axi_rresp    (dst_b_bus.rresp),
       .s_axi_rlast    (dst_b_bus.rlast),
       .s_axi_rvalid   (dst_b_bus.rvalid),
       .s_axi_rready   (dst_b_bus.rready),  
       .m_axi_awid     (ddr_b_bus.awid[6:0]),   
       .m_axi_awaddr   (ddr_b_bus.awaddr), 
       .m_axi_awlen    (ddr_b_bus.awlen),
       .m_axi_awsize   (ddr_b_bus.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),   
       .m_axi_awvalid  (ddr_b_bus.awvalid),
       .m_axi_awready  (ddr_b_bus.awready),
       .m_axi_wdata    (ddr_b_bus.wdata),  
       .m_axi_wstrb    (ddr_b_bus.wstrb),  
       .m_axi_wlast    (ddr_b_bus.wlast),  
       .m_axi_wvalid   (ddr_b_bus.wvalid), 
       .m_axi_wready   (ddr_b_bus.wready), 
       .m_axi_bid      (ddr_b_bus.bid),    
       .m_axi_bresp    (ddr_b_bus.bresp),  
       .m_axi_bvalid   (ddr_b_bus.bvalid), 
       .m_axi_bready   (ddr_b_bus.bready), 
       .m_axi_arid     (ddr_b_bus.arid[6:0]),   
       .m_axi_araddr   (ddr_b_bus.araddr), 
       .m_axi_arlen    (ddr_b_bus.arlen),
       .m_axi_arsize   (ddr_b_bus.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),   
       .m_axi_arvalid  (ddr_b_bus.arvalid),
       .m_axi_arready  (ddr_b_bus.arready),
       .m_axi_rid      (ddr_b_bus.rid),    
       .m_axi_rdata    (ddr_b_bus.rdata),  
       .m_axi_rresp    (ddr_b_bus.rresp),  
       .m_axi_rlast    (ddr_b_bus.rlast),  
       .m_axi_rvalid   (ddr_b_bus.rvalid), 
       .m_axi_rready   (ddr_b_bus.rready)
);

assign ddr_b_bus.awid[15:7] = 9'b0;
assign ddr_b_bus.arid[15:7] = 9'b0;

// DDR D
src_register_slice DDR_D_TST_AXI4_REG_SLC_1 (
	.aclk           (clk),
    .aresetn        (slr1_rst_n),
    .s_axi_awid     (src_d_bus.awid),
	.s_axi_awaddr   ({src_d_bus.awaddr[63:36], 2'b0, src_d_bus.awaddr[33:0]}),
	.s_axi_awlen    (src_d_bus.awlen),
	.s_axi_awsize   (src_d_bus.awsize),
	.s_axi_awburst  (2'b1),
	.s_axi_awlock   (1'b0),
	.s_axi_awcache  (4'b11),
	.s_axi_awprot   (3'b10),
	.s_axi_awregion (4'b0),
	.s_axi_awqos    (4'b0),
	.s_axi_awvalid  (src_d_bus.awvalid),
	.s_axi_awready  (src_d_bus.awready),
	.s_axi_wdata    (src_d_bus.wdata),
	.s_axi_wstrb    (src_d_bus.wstrb),
	.s_axi_wlast    (src_d_bus.wlast),
	.s_axi_wvalid   (src_d_bus.wvalid),
	.s_axi_wready   (src_d_bus.wready),
	.s_axi_bid      (src_d_bus.bid),
	.s_axi_bresp    (src_d_bus.bresp),
	.s_axi_bvalid   (src_d_bus.bvalid),
	.s_axi_bready   (src_d_bus.bready),
	.s_axi_arid     (src_d_bus.arid),
	.s_axi_araddr   ({src_d_bus.araddr[63:36], 2'b0, src_d_bus.araddr[33:0]}),
	.s_axi_arlen    (src_d_bus.arlen),
	.s_axi_arsize   (src_d_bus.arsize),
	.s_axi_arburst  (2'b1),
	.s_axi_arlock   (1'b0),
	.s_axi_arcache  (4'b11),
	.s_axi_arprot   (3'b10),
	.s_axi_arregion (4'b0),
	.s_axi_arqos    (4'b0),
	.s_axi_arvalid  (src_d_bus.arvalid),
	.s_axi_arready  (src_d_bus.arready),
	.s_axi_rid      (src_d_bus.rid),
	.s_axi_rdata    (src_d_bus.rdata),
	.s_axi_rresp    (src_d_bus.rresp),
	.s_axi_rlast    (src_d_bus.rlast),
	.s_axi_rvalid   (src_d_bus.rvalid),
	.s_axi_rready   (src_d_bus.rready),  
	.m_axi_awid     (dst_d_bus.awid),   
	.m_axi_awaddr   (dst_d_bus.awaddr), 
	.m_axi_awlen    (dst_d_bus.awlen),
	.m_axi_awsize   (dst_d_bus.awsize),
	.m_axi_awburst  (),
	.m_axi_awlock   (),
	.m_axi_awcache  (),
	.m_axi_awprot   (),
	.m_axi_awregion (),
	.m_axi_awqos    (),  
	.m_axi_awvalid  (dst_d_bus.awvalid),
	.m_axi_awready  (dst_d_bus.awready),
	.m_axi_wdata    (dst_d_bus.wdata),  
	.m_axi_wstrb    (dst_d_bus.wstrb),  
	.m_axi_wlast    (dst_d_bus.wlast),  
	.m_axi_wvalid   (dst_d_bus.wvalid), 
	.m_axi_wready   (dst_d_bus.wready), 
	.m_axi_bid      (dst_d_bus.bid),    
	.m_axi_bresp    (dst_d_bus.bresp),  
	.m_axi_bvalid   (dst_d_bus.bvalid), 
	.m_axi_bready   (dst_d_bus.bready), 
	.m_axi_arid     (dst_d_bus.arid),   
	.m_axi_araddr   (dst_d_bus.araddr), 
	.m_axi_arlen    (dst_d_bus.arlen),  
	.m_axi_arsize   (dst_d_bus.arsize),
	.m_axi_arburst  (),
	.m_axi_arlock   (),
	.m_axi_arcache  (),
	.m_axi_arprot   (),
	.m_axi_arregion (),
	.m_axi_arqos    (), 
	.m_axi_arvalid  (dst_d_bus.arvalid),
	.m_axi_arready  (dst_d_bus.arready),
	.m_axi_rid      (dst_d_bus.rid),    
	.m_axi_rdata    (dst_d_bus.rdata),  
	.m_axi_rresp    (dst_d_bus.rresp),  
	.m_axi_rlast    (dst_d_bus.rlast),  
	.m_axi_rvalid   (dst_d_bus.rvalid), 
	.m_axi_rready   (dst_d_bus.rready)
);

dest_register_slice DDR_D_TST_AXI4_REG_SLC_2 (
       .aclk           (clk),
       .aresetn        (slr0_rst_n),
       .s_axi_awid     (dst_d_bus.awid),
       .s_axi_awaddr   (dst_d_bus.awaddr),
       .s_axi_awlen    (dst_d_bus.awlen),
       .s_axi_awsize   (dst_d_bus.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (dst_d_bus.awvalid),
       .s_axi_awready  (dst_d_bus.awready),
       .s_axi_wdata    (dst_d_bus.wdata),
       .s_axi_wstrb    (dst_d_bus.wstrb),
       .s_axi_wlast    (dst_d_bus.wlast),
       .s_axi_wvalid   (dst_d_bus.wvalid),
       .s_axi_wready   (dst_d_bus.wready),
       .s_axi_bid      (dst_d_bus.bid),
       .s_axi_bresp    (dst_d_bus.bresp),
       .s_axi_bvalid   (dst_d_bus.bvalid),
       .s_axi_bready   (dst_d_bus.bready),
       .s_axi_arid     (dst_d_bus.arid),
       .s_axi_araddr   (dst_d_bus.araddr),
       .s_axi_arlen    (dst_d_bus.arlen),
       .s_axi_arsize   (dst_d_bus.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (dst_d_bus.arvalid),
       .s_axi_arready  (dst_d_bus.arready),
       .s_axi_rid      (dst_d_bus.rid),
       .s_axi_rdata    (dst_d_bus.rdata),
       .s_axi_rresp    (dst_d_bus.rresp),
       .s_axi_rlast    (dst_d_bus.rlast),
       .s_axi_rvalid   (dst_d_bus.rvalid),
       .s_axi_rready   (dst_d_bus.rready),  
       .m_axi_awid     (ddr_d_bus.awid[6:0]),   
       .m_axi_awaddr   (ddr_d_bus.awaddr), 
       .m_axi_awlen    (ddr_d_bus.awlen),
       .m_axi_awsize   (ddr_d_bus.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),   
       .m_axi_awvalid  (ddr_d_bus.awvalid),
       .m_axi_awready  (ddr_d_bus.awready),
       .m_axi_wdata    (ddr_d_bus.wdata),  
       .m_axi_wstrb    (ddr_d_bus.wstrb),  
       .m_axi_wlast    (ddr_d_bus.wlast),  
       .m_axi_wvalid   (ddr_d_bus.wvalid), 
       .m_axi_wready   (ddr_d_bus.wready), 
       .m_axi_bid      (ddr_d_bus.bid),    
       .m_axi_bresp    (ddr_d_bus.bresp),  
       .m_axi_bvalid   (ddr_d_bus.bvalid), 
       .m_axi_bready   (ddr_d_bus.bready), 
       .m_axi_arid     (ddr_d_bus.arid[6:0]),   
       .m_axi_araddr   (ddr_d_bus.araddr), 
       .m_axi_arlen    (ddr_d_bus.arlen),
       .m_axi_arsize   (ddr_d_bus.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),   
       .m_axi_arvalid  (ddr_d_bus.arvalid),
       .m_axi_arready  (ddr_d_bus.arready),
       .m_axi_rid      (ddr_d_bus.rid),    
       .m_axi_rdata    (ddr_d_bus.rdata),  
       .m_axi_rresp    (ddr_d_bus.rresp),  
       .m_axi_rlast    (ddr_d_bus.rlast),  
       .m_axi_rvalid   (ddr_d_bus.rvalid), 
       .m_axi_rready   (ddr_d_bus.rready)
);

assign ddr_d_bus.awid[15:7] = 9'b0;
assign ddr_d_bus.arid[15:7] = 9'b0;

// DDR C
axi_register_slice DDR_C_TST_AXI4_REG_SLC (
	.aclk           (clk),
	.aresetn        (slr1_rst_n),

	.s_axi_awid     (src_c_bus.awid),
	.s_axi_awaddr   ({src_c_bus.awaddr[63:36], 2'b0, src_c_bus.awaddr[33:0]}),
	.s_axi_awlen    (src_c_bus.awlen),
	.s_axi_awsize   (src_c_bus.awsize),
	.s_axi_awvalid  (src_c_bus.awvalid),
	.s_axi_awready  (src_c_bus.awready),
	.s_axi_wdata    (src_c_bus.wdata),
	.s_axi_wstrb    (src_c_bus.wstrb),
	.s_axi_wlast    (src_c_bus.wlast),
	.s_axi_wvalid   (src_c_bus.wvalid),
	.s_axi_wready   (src_c_bus.wready),
	.s_axi_bid      (src_c_bus.bid),
	.s_axi_bresp    (src_c_bus.bresp),
	.s_axi_bvalid   (src_c_bus.bvalid),
	.s_axi_bready   (src_c_bus.bready),
	.s_axi_arid     (src_c_bus.arid),
	.s_axi_araddr   ({src_c_bus.araddr[63:36], 2'b0, src_c_bus.araddr[33:0]}),
	.s_axi_arlen    (src_c_bus.arlen),
	.s_axi_arsize   (src_c_bus.arsize),
	.s_axi_arvalid  (src_c_bus.arvalid),
	.s_axi_arready  (src_c_bus.arready),
	.s_axi_rid      (src_c_bus.rid),
	.s_axi_rdata    (src_c_bus.rdata),
	.s_axi_rresp    (src_c_bus.rresp),
	.s_axi_rlast    (src_c_bus.rlast),
	.s_axi_rvalid   (src_c_bus.rvalid),
	.s_axi_rready   (src_c_bus.rready),  
	.m_axi_awid     (ddr_c_bus.awid),   
	.m_axi_awaddr   (ddr_c_bus.awaddr), 
	.m_axi_awlen    (ddr_c_bus.awlen),  
	.m_axi_awsize   (ddr_c_bus.awsize),
	.m_axi_awvalid  (ddr_c_bus.awvalid),
	.m_axi_awready  (ddr_c_bus.awready),
	.m_axi_wdata    (ddr_c_bus.wdata),  
	.m_axi_wstrb    (ddr_c_bus.wstrb),  
	.m_axi_wlast    (ddr_c_bus.wlast),  
	.m_axi_wvalid   (ddr_c_bus.wvalid), 
	.m_axi_wready   (ddr_c_bus.wready), 
	.m_axi_bid      (ddr_c_bus.bid),    
	.m_axi_bresp    (ddr_c_bus.bresp),  
	.m_axi_bvalid   (ddr_c_bus.bvalid), 
	.m_axi_bready   (ddr_c_bus.bready), 
	.m_axi_arid     (ddr_c_bus.arid),   
	.m_axi_araddr   (ddr_c_bus.araddr), 
	.m_axi_arlen    (ddr_c_bus.arlen),  
	.m_axi_arsize   (ddr_c_bus.arsize),
	.m_axi_arvalid  (ddr_c_bus.arvalid),
	.m_axi_arready  (ddr_c_bus.arready),
	.m_axi_rid      (ddr_c_bus.rid),    
	.m_axi_rdata    (ddr_c_bus.rdata),  
	.m_axi_rresp    (ddr_c_bus.rresp),  
	.m_axi_rlast    (ddr_c_bus.rlast),  
	.m_axi_rvalid   (ddr_c_bus.rvalid), 
	.m_axi_rready   (ddr_c_bus.rready)
);








endmodule

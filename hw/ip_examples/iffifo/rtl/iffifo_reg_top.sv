// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`


`include "common_cells/assertions.svh"

module iffifo_reg_top #(
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
    parameter int AW = 4
) (
    input logic clk_i,
    input logic rst_ni,
    input reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,

    // Output port for window
    output reg_req_t [2-1:0] reg_req_win_o,
    input  reg_rsp_t [2-1:0] reg_rsp_win_i,

    // To HW
    output iffifo_reg_pkg::iffifo_reg2hw_t reg2hw,  // Write
    input  iffifo_reg_pkg::iffifo_hw2reg_t hw2reg,  // Read


    // Config
    input devmode_i  // If 1, explicit error return for unmapped register access
);

  import iffifo_reg_pkg::*;

  localparam int DW = 32;
  localparam int DBW = DW / 8;  // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [ AW-1:0] reg_addr;
  logic [ DW-1:0] reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [ DW-1:0] reg_rdata;
  logic           reg_error;

  logic addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  // Below register interface can be changed
  reg_req_t reg_intf_req;
  reg_rsp_t reg_intf_rsp;


  logic [1:0] reg_steer;

  reg_req_t [3-1:0] reg_intf_demux_req;
  reg_rsp_t [3-1:0] reg_intf_demux_rsp;

  // demux connection
  assign reg_intf_req = reg_intf_demux_req[2];
  assign reg_intf_demux_rsp[2] = reg_intf_rsp;

  assign reg_req_win_o[0] = reg_intf_demux_req[0];
  assign reg_intf_demux_rsp[0] = reg_rsp_win_i[0];
  assign reg_req_win_o[1] = reg_intf_demux_req[1];
  assign reg_intf_demux_rsp[1] = reg_rsp_win_i[1];

  // Create Socket_1n
  reg_demux #(
      .NoPorts(3),
      .req_t  (reg_req_t),
      .rsp_t  (reg_rsp_t)
  ) i_reg_demux (
      .clk_i,
      .rst_ni,
      .in_req_i(reg_req_i),
      .in_rsp_o(reg_rsp_o),
      .out_req_o(reg_intf_demux_req),
      .out_rsp_i(reg_intf_demux_rsp),
      .in_select_i(reg_steer)
  );


  // Create steering logic
  always_comb begin
    reg_steer = 2;  // Default set to register

    // TODO: Can below codes be unique case () inside ?
    if (reg_req_i.addr[AW-1:0] >= 8 && reg_req_i.addr[AW-1:0] < 12) begin
      reg_steer = 0;
    end
    if (reg_req_i.addr[AW-1:0] >= 12) begin
      reg_steer = 1;
    end
  end


  assign reg_we = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr = reg_intf_req.addr;
  assign reg_wdata = reg_intf_req.wdata;
  assign reg_be = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;
  assign reg_intf_rsp.ready = 1'b1;

  assign reg_rdata = reg_rdata_next;
  assign reg_error = (devmode_i & addrmiss) | wr_err;


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic [31:0] dummyr_qs;
  logic [31:0] dummyr_wd;
  logic dummyr_we;
  logic [31:0] dummyw_qs;

  // Register instances
  // R[dummyr]: V(False)

  prim_subreg #(
      .DW      (32),
      .SWACCESS("RW"),
      .RESVAL  (32'h0)
  ) u_dummyr (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      // from register interface
      .we(dummyr_we),
      .wd(dummyr_wd),

      // from internal hardware
      .de(1'b0),
      .d ('0),

      // to internal hardware
      .qe(),
      .q (reg2hw.dummyr.q),

      // to register interface (read)
      .qs(dummyr_qs)
  );


  // R[dummyw]: V(False)

  prim_subreg #(
      .DW      (32),
      .SWACCESS("RO"),
      .RESVAL  (32'h0)
  ) u_dummyw (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .we(1'b0),
      .wd('0),

      // from internal hardware
      .de(hw2reg.dummyw.de),
      .d (hw2reg.dummyw.d),

      // to internal hardware
      .qe(),
      .q (reg2hw.dummyw.q),

      // to register interface (read)
      .qs(dummyw_qs)
  );




  logic [1:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[0] = (reg_addr == IFFIFO_DUMMYR_OFFSET);
    addr_hit[1] = (reg_addr == IFFIFO_DUMMYW_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[0] & (|(IFFIFO_PERMIT[0] & ~reg_be))) |
               (addr_hit[1] & (|(IFFIFO_PERMIT[1] & ~reg_be)))));
  end

  assign dummyr_we = addr_hit[0] & reg_we & !reg_error;
  assign dummyr_wd = reg_wdata[31:0];

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[31:0] = dummyr_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[31:0] = dummyw_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule

module iffifo_reg_top_intf #(
    parameter  int AW = 4,
    localparam int DW = 32
) (
    input logic clk_i,
    input logic rst_ni,
    REG_BUS.in regbus_slave,
    REG_BUS.out regbus_win_mst[2-1:0],
    // To HW
    output iffifo_reg_pkg::iffifo_reg2hw_t reg2hw,  // Write
    input iffifo_reg_pkg::iffifo_hw2reg_t hw2reg,  // Read
    // Config
    input devmode_i  // If 1, explicit error return for unmapped register access
);
  localparam int unsigned STRB_WIDTH = DW / 8;

  `include "register_interface/typedef.svh"
  `include "register_interface/assign.svh"

  // Define structs for reg_bus
  typedef logic [AW-1:0] addr_t;
  typedef logic [DW-1:0] data_t;
  typedef logic [STRB_WIDTH-1:0] strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, addr_t, data_t, strb_t)

  reg_bus_req_t s_reg_req;
  reg_bus_rsp_t s_reg_rsp;

  // Assign SV interface to structs
  `REG_BUS_ASSIGN_TO_REQ(s_reg_req, regbus_slave)
  `REG_BUS_ASSIGN_FROM_RSP(regbus_slave, s_reg_rsp)

  reg_bus_req_t s_reg_win_req[2-1:0];
  reg_bus_rsp_t s_reg_win_rsp[2-1:0];
  for (genvar i = 0; i < 2; i++) begin : gen_assign_window_structs
    `REG_BUS_ASSIGN_TO_REQ(s_reg_win_req[i], regbus_win_mst[i])
    `REG_BUS_ASSIGN_FROM_RSP(regbus_win_mst[i], s_reg_win_rsp[i])
  end



  iffifo_reg_top #(
      .reg_req_t(reg_bus_req_t),
      .reg_rsp_t(reg_bus_rsp_t),
      .AW(AW)
  ) i_regs (
      .clk_i,
      .rst_ni,
      .reg_req_i(s_reg_req),
      .reg_rsp_o(s_reg_rsp),
      .reg_req_win_o(s_reg_win_req),
      .reg_rsp_win_i(s_reg_win_rsp),
      .reg2hw,  // Write
      .hw2reg,  // Read
      .devmode_i
  );

endmodule



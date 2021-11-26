// Copyright lowRISC contributors.
// Copyright 2017 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                                                                            //
//                                                                            //
// Design Name:    RISC-V processor core                                      //
// Project Name:   ibex                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Defines for various constants used by the processor core.  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module ibex_if_stage (
	clk,
	rst_n,
	boot_addr_i,
	req_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_valid_id_o,
	instr_rdata_id_o,
	is_compressed_id_o,
	illegal_c_insn_id_o,
	pc_if_o,
	pc_id_o,
	clear_instr_valid_i,
	pc_set_i,
	exception_pc_reg_i,
	depc_i,
	pc_mux_i,
	exc_pc_mux_i,
	exc_vec_pc_mux_i,
	jump_target_ex_i,
	halt_if_i,
	id_ready_i,
	if_valid_o,
	if_busy_o,
	perf_imiss_o
);
	parameter DM_HALT_ADDRESS = 32'h1a110800;
	parameter DM_EXCEPTION_ADDRESS = 32'h1a110808;
	input wire clk;
	input wire rst_n;
	input wire [31:0] boot_addr_i;
	input wire req_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_rdata_i;
	output reg instr_valid_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg is_compressed_id_o;
	output reg illegal_c_insn_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	input wire clear_instr_valid_i;
	input wire pc_set_i;
	input wire [31:0] exception_pc_reg_i;
	input wire [31:0] depc_i;
	input wire [2:0] pc_mux_i;
	input wire [2:0] exc_pc_mux_i;
	input wire [5:0] exc_vec_pc_mux_i;
	input wire [31:0] jump_target_ex_i;
	input wire halt_if_i;
	input wire id_ready_i;
	output wire if_valid_o;
	output wire if_busy_o;
	output wire perf_imiss_o;
	reg offset_in_init_d;
	reg offset_in_init_q;
	reg valid;
	wire if_ready;
	wire prefetch_busy;
	reg branch_req;
	reg [31:0] fetch_addr_n;
	wire fetch_valid;
	reg fetch_ready;
	wire [31:0] fetch_rdata;
	wire [31:0] fetch_addr;
	reg [31:0] exc_pc;
	localparam [7:0] ibex_defines_EXC_OFF_BREAKPOINT = 8'h90;
	localparam [7:0] ibex_defines_EXC_OFF_ECALL = 8'h88;
	localparam [7:0] ibex_defines_EXC_OFF_ILLINSN = 8'h84;
	localparam [2:0] ibex_defines_EXC_PC_BREAKPOINT = 7;
	localparam [2:0] ibex_defines_EXC_PC_DBD = 5;
	localparam [2:0] ibex_defines_EXC_PC_DBGEXC = 6;
	localparam [2:0] ibex_defines_EXC_PC_ECALL = 1;
	localparam [2:0] ibex_defines_EXC_PC_ILLINSN = 0;
	localparam [2:0] ibex_defines_EXC_PC_IRQ = 4;
	always @(*) begin : EXC_PC_MUX
		exc_pc = {32 {1'sb0}};
		case (exc_pc_mux_i)
			ibex_defines_EXC_PC_ILLINSN: exc_pc = {boot_addr_i[31:8], {ibex_defines_EXC_OFF_ILLINSN}};
			ibex_defines_EXC_PC_ECALL: exc_pc = {boot_addr_i[31:8], {ibex_defines_EXC_OFF_ECALL}};
			ibex_defines_EXC_PC_BREAKPOINT: exc_pc = {boot_addr_i[31:8], {ibex_defines_EXC_OFF_BREAKPOINT}};
			ibex_defines_EXC_PC_IRQ: exc_pc = {boot_addr_i[31:8], {exc_vec_pc_mux_i}, 2'b00};
			ibex_defines_EXC_PC_DBD: exc_pc = {DM_HALT_ADDRESS};
			ibex_defines_EXC_PC_DBGEXC: exc_pc = {DM_EXCEPTION_ADDRESS};
			default:
				;
		endcase
	end
	localparam [7:0] ibex_defines_EXC_OFF_RST = 8'h80;
	localparam [2:0] ibex_defines_PC_BOOT = 0;
	localparam [2:0] ibex_defines_PC_DRET = 4;
	localparam [2:0] ibex_defines_PC_ERET = 3;
	localparam [2:0] ibex_defines_PC_EXCEPTION = 2;
	localparam [2:0] ibex_defines_PC_JUMP = 1;
	always @(*) begin
		fetch_addr_n = {32 {1'sb0}};
		case (pc_mux_i)
			ibex_defines_PC_BOOT: fetch_addr_n = {boot_addr_i[31:8], {ibex_defines_EXC_OFF_RST}};
			ibex_defines_PC_JUMP: fetch_addr_n = jump_target_ex_i;
			ibex_defines_PC_EXCEPTION: fetch_addr_n = exc_pc;
			ibex_defines_PC_ERET: fetch_addr_n = exception_pc_reg_i;
			ibex_defines_PC_DRET: fetch_addr_n = depc_i;
			default:
				;
		endcase
	end
	ibex_prefetch_buffer prefetch_buffer_i(
		.clk(clk),
		.rst_n(rst_n),
		.req_i(req_i),
		.branch_i(branch_req),
		.addr_i({fetch_addr_n[31:1], 1'b0}),
		.ready_i(fetch_ready),
		.valid_o(fetch_valid),
		.rdata_o(fetch_rdata),
		.addr_o(fetch_addr),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.busy_o(prefetch_busy)
	);
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			offset_in_init_q <= 1'b1;
		else
			offset_in_init_q <= offset_in_init_d;
	always @(*) begin
		offset_in_init_d = offset_in_init_q;
		fetch_ready = 1'b0;
		branch_req = 1'b0;
		valid = 1'b0;
		if (offset_in_init_q) begin
			if (req_i) begin
				branch_req = 1'b1;
				offset_in_init_d = 1'b0;
			end
		end
		else if (fetch_valid) begin
			valid = 1'b1;
			if (req_i && if_valid_o) begin
				fetch_ready = 1'b1;
				offset_in_init_d = 1'b0;
			end
		end
		if (pc_set_i) begin
			valid = 1'b0;
			branch_req = 1'b1;
			offset_in_init_d = 1'b0;
		end
	end
	assign pc_if_o = fetch_addr;
	assign if_busy_o = prefetch_busy;
	assign perf_imiss_o = ~fetch_valid | branch_req;
	wire [31:0] instr_decompressed;
	wire illegal_c_insn;
	wire instr_compressed_int;
	ibex_compressed_decoder compressed_decoder_i(
		.instr_i(fetch_rdata),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_compressed_int),
		.illegal_instr_o(illegal_c_insn)
	);
	always @(posedge clk or negedge rst_n) begin : IF_ID_PIPE_REGISTERS
		if (!rst_n) begin
			instr_valid_id_o <= 1'b0;
			instr_rdata_id_o <= {32 {1'sb0}};
			illegal_c_insn_id_o <= 1'b0;
			is_compressed_id_o <= 1'b0;
			pc_id_o <= {32 {1'sb0}};
		end
		else if (if_valid_o) begin
			instr_valid_id_o <= 1'b1;
			instr_rdata_id_o <= instr_decompressed;
			illegal_c_insn_id_o <= illegal_c_insn;
			is_compressed_id_o <= instr_compressed_int;
			pc_id_o <= pc_if_o;
		end
		else if (clear_instr_valid_i)
			instr_valid_id_o <= 1'b0;
	end
	assign if_ready = valid & id_ready_i;
	assign if_valid_o = ~halt_if_i & if_ready;
endmodule

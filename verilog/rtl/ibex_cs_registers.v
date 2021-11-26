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

module ibex_cs_registers (
	clk,
	rst_n,
	core_id_i,
	cluster_id_i,
	boot_addr_i,
	csr_access_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_rdata_o,
	m_irq_enable_o,
	mepc_o,
	debug_cause_i,
	debug_csr_save_i,
	depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	pc_if_i,
	pc_id_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_restore_mret_i,
	csr_restore_dret_i,
	csr_cause_i,
	csr_save_cause_i,
	if_valid_i,
	id_valid_i,
	is_compressed_i,
	is_decoding_i,
	imiss_i,
	pc_set_i,
	jump_i,
	branch_i,
	branch_taken_i,
	mem_load_i,
	mem_store_i,
	ext_counters_i
);
	parameter N_EXT_CNT = 0;
	parameter [0:0] RV32E = 0;
	parameter [0:0] RV32M = 0;
	input wire clk;
	input wire rst_n;
	input wire [3:0] core_id_i;
	input wire [5:0] cluster_id_i;
	input wire [31:0] boot_addr_i;
	input wire csr_access_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	input wire [1:0] csr_op_i;
	output wire [31:0] csr_rdata_o;
	output wire m_irq_enable_o;
	output wire [31:0] mepc_o;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_dret_i;
	input wire [5:0] csr_cause_i;
	input wire csr_save_cause_i;
	input wire if_valid_i;
	input wire id_valid_i;
	input wire is_compressed_i;
	input wire is_decoding_i;
	input wire imiss_i;
	input wire pc_set_i;
	input wire jump_i;
	input wire branch_i;
	input wire branch_taken_i;
	input wire mem_load_i;
	input wire mem_store_i;
	input wire [N_EXT_CNT - 1:0] ext_counters_i;
	localparam [1:0] MXL = 2'd1;
	localparam [31:0] MISA_VALUE = ((((((((((0 | 4) | 0) | (RV32E << 4)) | 0) | 256) | (RV32M << 12)) | 0) | 0) | 0) | 0) | (MXL << 30);
	localparam N_PERF_COUNTERS = 11 + N_EXT_CNT;
	localparam N_PERF_REGS = N_PERF_COUNTERS;
	wire [N_PERF_COUNTERS - 1:0] PCCR_in;
	reg [N_PERF_COUNTERS - 1:0] PCCR_inc;
	reg [N_PERF_COUNTERS - 1:0] PCCR_inc_q;
	reg [(N_PERF_REGS * 32) - 1:0] PCCR_q;
	reg [(N_PERF_REGS * 32) - 1:0] PCCR_n;
	reg [1:0] PCMR_n;
	reg [1:0] PCMR_q;
	reg [N_PERF_COUNTERS - 1:0] PCER_n;
	reg [N_PERF_COUNTERS - 1:0] PCER_q;
	reg [31:0] perf_rdata;
	reg [4:0] pccr_index;
	reg pccr_all_sel;
	reg is_pccr;
	reg is_pcer;
	reg is_pcmr;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	reg csr_we_int;
	reg [31:0] mepc_q;
	reg [31:0] mepc_n;
	reg [31:0] dcsr_q;
	reg [31:0] dcsr_n;
	reg [31:0] depc_q;
	reg [31:0] depc_n;
	reg [31:0] dscratch0_q;
	reg [31:0] dscratch0_n;
	reg [31:0] dscratch1_q;
	reg [31:0] dscratch1_n;
	reg [5:0] mcause_q;
	reg [5:0] mcause_n;
	reg [3:0] mstatus_q;
	reg [3:0] mstatus_n;
	reg [31:0] exception_pc;
	localparam [11:0] ibex_defines_CSR_DCSR = 12'h7b0;
	localparam [11:0] ibex_defines_CSR_DPC = 12'h7b1;
	localparam [11:0] ibex_defines_CSR_DSCRATCH0 = 12'h7b2;
	localparam [11:0] ibex_defines_CSR_DSCRATCH1 = 12'h7b3;
	localparam [11:0] ibex_defines_CSR_MCAUSE = 12'h342;
	localparam [11:0] ibex_defines_CSR_MEPC = 12'h341;
	localparam [11:0] ibex_defines_CSR_MHARTID = 12'hf14;
	localparam [11:0] ibex_defines_CSR_MISA = 12'h301;
	localparam [11:0] ibex_defines_CSR_MSTATUS = 12'h300;
	localparam [11:0] ibex_defines_CSR_MTVEC = 12'h305;
	always @(*) begin
		csr_rdata_int = {32 {1'sb0}};
		case (csr_addr_i)
			ibex_defines_CSR_MSTATUS: csr_rdata_int = {19'b0000000000000000000, mstatus_q[1-:2], 3'b000, mstatus_q[2], 3'h0, mstatus_q[3], 3'h0};
			ibex_defines_CSR_MTVEC: csr_rdata_int = boot_addr_i;
			ibex_defines_CSR_MEPC: csr_rdata_int = mepc_q;
			ibex_defines_CSR_MCAUSE: csr_rdata_int = {mcause_q[5], 26'b00000000000000000000000000, mcause_q[4:0]};
			ibex_defines_CSR_MHARTID: csr_rdata_int = {21'b000000000000000000000, cluster_id_i[5:0], 1'b0, core_id_i[3:0]};
			ibex_defines_CSR_MISA: csr_rdata_int = MISA_VALUE;
			ibex_defines_CSR_DCSR: csr_rdata_int = dcsr_q;
			ibex_defines_CSR_DPC: csr_rdata_int = depc_q;
			ibex_defines_CSR_DSCRATCH0: csr_rdata_int = dscratch0_q;
			ibex_defines_CSR_DSCRATCH1: csr_rdata_int = dscratch1_q;
			default:
				;
		endcase
	end
	localparam [1:0] ibex_defines_PRIV_LVL_M = 2'b11;
	localparam [3:0] ibex_defines_XDEBUGVER_STD = 4'd4;
	always @(*) begin
		mepc_n = mepc_q;
		depc_n = depc_q;
		dcsr_n = dcsr_q;
		dscratch0_n = dscratch0_q;
		dscratch1_n = dscratch1_q;
		mstatus_n = mstatus_q;
		mcause_n = mcause_q;
		exception_pc = pc_id_i;
		case (csr_addr_i)
			ibex_defines_CSR_MSTATUS:
				if (csr_we_int)
					mstatus_n = {csr_wdata_int[3], csr_wdata_int[7], ibex_defines_PRIV_LVL_M};
			ibex_defines_CSR_MEPC:
				if (csr_we_int)
					mepc_n = csr_wdata_int;
			ibex_defines_CSR_MCAUSE:
				if (csr_we_int)
					mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
			ibex_defines_CSR_DCSR:
				if (csr_we_int) begin
					dcsr_n = csr_wdata_int;
					dcsr_n[31-:4] = ibex_defines_XDEBUGVER_STD;
					dcsr_n[1-:2] = ibex_defines_PRIV_LVL_M;
					dcsr_n[3] = 1'b0;
					dcsr_n[4] = 1'b0;
					dcsr_n[10] = 1'b0;
					dcsr_n[9] = 1'b0;
					dcsr_n[5] = 1'b0;
					dcsr_n[14] = 1'b0;
					dcsr_n[27-:12] = 12'h000;
				end
			ibex_defines_CSR_DPC:
				if (csr_we_int && (csr_wdata_int[0] == 1'b0))
					depc_n = csr_wdata_int;
			ibex_defines_CSR_DSCRATCH0:
				if (csr_we_int)
					dscratch0_n = csr_wdata_int;
			ibex_defines_CSR_DSCRATCH1:
				if (csr_we_int)
					dscratch1_n = csr_wdata_int;
			default:
				;
		endcase
		case (1'b1)
			csr_save_cause_i: begin
				case (1'b1)
					csr_save_if_i: exception_pc = pc_if_i;
					csr_save_id_i: exception_pc = pc_id_i;
					default:
						;
				endcase
				if (debug_csr_save_i) begin
					dcsr_n[1-:2] = ibex_defines_PRIV_LVL_M;
					dcsr_n[8-:3] = debug_cause_i;
					depc_n = exception_pc;
				end
				else begin
					mstatus_n[2] = mstatus_q[3];
					mstatus_n[3] = 1'b0;
					mstatus_n[1-:2] = ibex_defines_PRIV_LVL_M;
					mepc_n = exception_pc;
					mcause_n = csr_cause_i;
				end
			end
			csr_restore_mret_i: begin
				mstatus_n[3] = mstatus_q[2];
				mstatus_n[2] = 1'b1;
			end
			csr_restore_dret_i: begin
				mstatus_n[3] = mstatus_q[2];
				mstatus_n[2] = 1'b1;
			end
			default:
				;
		endcase
	end
	localparam [1:0] ibex_defines_CSR_OP_CLEAR = 3;
	localparam [1:0] ibex_defines_CSR_OP_NONE = 0;
	localparam [1:0] ibex_defines_CSR_OP_SET = 2;
	localparam [1:0] ibex_defines_CSR_OP_WRITE = 1;
	always @(*) begin
		csr_wdata_int = csr_wdata_i;
		csr_we_int = 1'b1;
		case (csr_op_i)
			ibex_defines_CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;
			ibex_defines_CSR_OP_SET: csr_wdata_int = csr_wdata_i | csr_rdata_o;
			ibex_defines_CSR_OP_CLEAR: csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			ibex_defines_CSR_OP_NONE: begin
				csr_wdata_int = csr_wdata_i;
				csr_we_int = 1'b0;
			end
			default:
				;
		endcase
	end
	assign csr_rdata_o = ((is_pccr || is_pcer) || is_pcmr ? perf_rdata : csr_rdata_int);
	assign m_irq_enable_o = mstatus_q[3];
	assign mepc_o = mepc_q;
	assign depc_o = depc_q;
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			mstatus_q <= {2'b00, ibex_defines_PRIV_LVL_M};
			mepc_q <= {32 {1'sb0}};
			mcause_q <= {6 {1'sb0}};
			depc_q <= {32 {1'sb0}};
			dcsr_q <= {30'b000000000000000000000000000000, ibex_defines_PRIV_LVL_M};
			dscratch0_q <= {32 {1'sb0}};
			dscratch1_q <= {32 {1'sb0}};
		end
		else begin
			mstatus_q <= {mstatus_n[3], mstatus_n[2], ibex_defines_PRIV_LVL_M};
			mepc_q <= mepc_n;
			mcause_q <= mcause_n;
			depc_q <= depc_n;
			dcsr_q <= dcsr_n;
			dscratch0_q <= dscratch0_n;
			dscratch1_q <= dscratch1_n;
		end
	wire [11:0] csr_addr;
	assign csr_addr = {csr_addr_i};
	assign PCCR_in[0] = 1'b1;
	assign PCCR_in[1] = if_valid_i;
	assign PCCR_in[2] = 1'b0;
	assign PCCR_in[3] = 1'b0;
	assign PCCR_in[4] = imiss_i & ~pc_set_i;
	assign PCCR_in[5] = mem_load_i;
	assign PCCR_in[6] = mem_store_i;
	assign PCCR_in[7] = jump_i;
	assign PCCR_in[8] = branch_i;
	assign PCCR_in[9] = branch_taken_i;
	assign PCCR_in[10] = (id_valid_i & is_decoding_i) & is_compressed_i;
	generate
		genvar i;
		for (i = 0; i < N_EXT_CNT; i = i + 1) begin : gen_extcounters
			assign PCCR_in[(N_PERF_COUNTERS - N_EXT_CNT) + i] = ext_counters_i[i];
		end
	endgenerate
	localparam [11:0] ibex_defines_CSR_PCCR31 = 12'h79f;
	localparam [11:0] ibex_defines_CSR_TDATA1 = 12'h7a1;
	localparam [11:0] ibex_defines_CSR_TSELECT = 12'h7a0;
	always @(*) begin
		is_pccr = 1'b0;
		is_pcmr = 1'b0;
		is_pcer = 1'b0;
		pccr_all_sel = 1'b0;
		pccr_index = {5 {1'sb0}};
		perf_rdata = {32 {1'sb0}};
		if (csr_access_i) begin
			case (csr_addr_i)
				ibex_defines_CSR_TSELECT: begin
					is_pcer = 1'b1;
					perf_rdata[N_PERF_COUNTERS - 1:0] = PCER_q;
				end
				ibex_defines_CSR_TDATA1: begin
					is_pcmr = 1'b1;
					perf_rdata[1:0] = PCMR_q;
				end
				ibex_defines_CSR_PCCR31: begin
					is_pccr = 1'b1;
					pccr_all_sel = 1'b1;
				end
				default:
					;
			endcase
			if (csr_addr[11:5] == 7'b0111100) begin
				is_pccr = 1'b1;
				pccr_index = csr_addr[4:0];
				perf_rdata = (csr_addr[4:0] < N_PERF_COUNTERS ? PCCR_q[csr_addr[4:0] * 32+:32] : {32 {1'sb0}});
			end
		end
	end
	always @(*) begin : sv2v_autoblock_2
		reg signed [31:0] c;
		for (c = 0; c < N_PERF_COUNTERS; c = c + 1)
			begin : PERF_CNT_INC
				PCCR_inc[c] = (PCCR_in[c] & PCER_q[c]) & PCMR_q[0];
				PCCR_n[c * 32+:32] = PCCR_q[c * 32+:32];
				if ((PCCR_inc_q[c] == 1'b1) && ((PCCR_q[c * 32+:32] != 32'hffffffff) || (PCMR_q[1] == 1'b0)))
					PCCR_n[c * 32+:32] = PCCR_q[c * 32+:32] + 32'h00000001;
				if (is_pccr && (pccr_all_sel || (pccr_index == c)))
					case (csr_op_i)
						ibex_defines_CSR_OP_NONE:
							;
						ibex_defines_CSR_OP_WRITE: PCCR_n[c * 32+:32] = csr_wdata_i;
						ibex_defines_CSR_OP_SET: PCCR_n[c * 32+:32] = csr_wdata_i | PCCR_q[c * 32+:32];
						ibex_defines_CSR_OP_CLEAR: PCCR_n[c * 32+:32] = csr_wdata_i & ~PCCR_q[c * 32+:32];
					endcase
			end
	end
	always @(*) begin
		PCMR_n = PCMR_q;
		PCER_n = PCER_q;
		if (is_pcmr)
			case (csr_op_i)
				ibex_defines_CSR_OP_NONE:
					;
				ibex_defines_CSR_OP_WRITE: PCMR_n = csr_wdata_i[1:0];
				ibex_defines_CSR_OP_SET: PCMR_n = csr_wdata_i[1:0] | PCMR_q;
				ibex_defines_CSR_OP_CLEAR: PCMR_n = csr_wdata_i[1:0] & ~PCMR_q;
			endcase
		if (is_pcer)
			case (csr_op_i)
				ibex_defines_CSR_OP_NONE:
					;
				ibex_defines_CSR_OP_WRITE: PCER_n = csr_wdata_i[N_PERF_COUNTERS - 1:0];
				ibex_defines_CSR_OP_SET: PCER_n = csr_wdata_i[N_PERF_COUNTERS - 1:0] | PCER_q;
				ibex_defines_CSR_OP_CLEAR: PCER_n = csr_wdata_i[N_PERF_COUNTERS - 1:0] & ~PCER_q;
			endcase
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			PCER_q <= {N_PERF_COUNTERS {1'sb0}};
			PCMR_q <= 2'h3;
			begin : sv2v_autoblock_3
				reg signed [31:0] r;
				for (r = 0; r < N_PERF_REGS; r = r + 1)
					begin
						PCCR_q[r * 32+:32] <= {32 {1'sb0}};
						PCCR_inc_q[r] <= 1'b0;
					end
			end
		end
		else begin
			PCER_q <= PCER_n;
			PCMR_q <= PCMR_n;
			begin : sv2v_autoblock_4
				reg signed [31:0] r;
				for (r = 0; r < N_PERF_REGS; r = r + 1)
					begin
						PCCR_q[r * 32+:32] <= PCCR_n[r * 32+:32];
						PCCR_inc_q[r] <= PCCR_inc[r];
					end
			end
		end
endmodule

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

module ibex_controller (
	clk,
	rst_n,
	fetch_enable_i,
	ctrl_busy_o,
	first_fetch_o,
	is_decoding_o,
	deassert_we_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	dret_insn_i,
	pipe_flush_i,
	ebrk_insn_i,
	csr_status_i,
	instr_valid_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	data_misaligned_i,
	branch_in_id_i,
	branch_set_i,
	jump_set_i,
	instr_multicyle_i,
	irq_i,
	irq_req_ctrl_i,
	irq_id_ctrl_i,
	m_IE_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	exc_ack_o,
	exc_kill_o,
	debug_req_i,
	debug_cause_o,
	debug_csr_save_o,
	debug_single_step_i,
	debug_ebreakm_i,
	csr_save_if_o,
	csr_save_id_o,
	csr_cause_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	operand_a_fw_mux_sel_o,
	halt_if_o,
	halt_id_o,
	id_ready_i,
	perf_jump_o,
	perf_tbranch_o
);
	input wire clk;
	input wire rst_n;
	input wire fetch_enable_i;
	output reg ctrl_busy_o;
	output reg first_fetch_o;
	output reg is_decoding_o;
	output wire deassert_we_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire dret_insn_i;
	input wire pipe_flush_i;
	input wire ebrk_insn_i;
	input wire csr_status_i;
	input wire instr_valid_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [2:0] pc_mux_o;
	output reg [2:0] exc_pc_mux_o;
	input wire data_misaligned_i;
	input wire branch_in_id_i;
	input wire branch_set_i;
	input wire jump_set_i;
	input wire instr_multicyle_i;
	input wire irq_i;
	input wire irq_req_ctrl_i;
	input wire [4:0] irq_id_ctrl_i;
	input wire m_IE_i;
	output reg irq_ack_o;
	output reg [4:0] irq_id_o;
	output reg [5:0] exc_cause_o;
	output reg exc_ack_o;
	output reg exc_kill_o;
	input wire debug_req_i;
	output reg [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg [5:0] csr_cause_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	output wire operand_a_fw_mux_sel_o;
	output reg halt_if_o;
	output reg halt_id_o;
	input wire id_ready_i;
	output reg perf_jump_o;
	output reg perf_tbranch_o;
	reg [3:0] ctrl_fsm_cs;
	reg [3:0] ctrl_fsm_ns;
	reg irq_enable_int;
	reg debug_mode_q;
	reg debug_mode_n;
	always @(negedge clk)
		if (is_decoding_o && illegal_insn_i)
			$display("%t: Illegal instruction (core %0d) at PC 0x%h: 0x%h", $time, ibex_core.core_id_i, ibex_id_stage.pc_id_i, ibex_id_stage.instr_rdata_i);
	localparam [3:0] BOOT_SET = 1;
	localparam [3:0] DBG_TAKEN_ID = 9;
	localparam [3:0] DBG_TAKEN_IF = 8;
	localparam [3:0] DECODE = 5;
	localparam [3:0] FIRST_FETCH = 4;
	localparam [3:0] FLUSH = 6;
	localparam [3:0] IRQ_TAKEN = 7;
	localparam [3:0] RESET = 0;
	localparam [3:0] SLEEP = 3;
	localparam [3:0] WAIT_SLEEP = 2;
	localparam [2:0] ibex_defines_DBG_CAUSE_EBREAK = 3'h1;
	localparam [2:0] ibex_defines_DBG_CAUSE_HALTREQ = 3'h3;
	localparam [2:0] ibex_defines_DBG_CAUSE_STEP = 3'h4;
	localparam [5:0] ibex_defines_EXC_CAUSE_BREAKPOINT = 6'h03;
	localparam [5:0] ibex_defines_EXC_CAUSE_CLEAR = 6'h00;
	localparam [5:0] ibex_defines_EXC_CAUSE_ECALL_MMODE = 6'h0b;
	localparam [5:0] ibex_defines_EXC_CAUSE_ILLEGAL_INSN = 6'h02;
	localparam [2:0] ibex_defines_EXC_PC_BREAKPOINT = 7;
	localparam [2:0] ibex_defines_EXC_PC_DBD = 5;
	localparam [2:0] ibex_defines_EXC_PC_DBGEXC = 6;
	localparam [2:0] ibex_defines_EXC_PC_ECALL = 1;
	localparam [2:0] ibex_defines_EXC_PC_ILLINSN = 0;
	localparam [2:0] ibex_defines_EXC_PC_IRQ = 4;
	localparam [2:0] ibex_defines_PC_BOOT = 0;
	localparam [2:0] ibex_defines_PC_DRET = 4;
	localparam [2:0] ibex_defines_PC_ERET = 3;
	localparam [2:0] ibex_defines_PC_EXCEPTION = 2;
	localparam [2:0] ibex_defines_PC_JUMP = 1;
	function automatic [5:0] sv2v_cast_6;
		input reg [5:0] inp;
		sv2v_cast_6 = inp;
	endfunction
	always @(*) begin
		instr_req_o = 1'b1;
		exc_ack_o = 1'b0;
		exc_kill_o = 1'b0;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		exc_cause_o = ibex_defines_EXC_CAUSE_CLEAR;
		exc_pc_mux_o = ibex_defines_EXC_PC_IRQ;
		csr_cause_o = ibex_defines_EXC_CAUSE_CLEAR;
		pc_mux_o = ibex_defines_PC_BOOT;
		pc_set_o = 1'b0;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		is_decoding_o = 1'b0;
		first_fetch_o = 1'b0;
		halt_if_o = 1'b0;
		halt_id_o = 1'b0;
		irq_ack_o = 1'b0;
		irq_id_o = irq_id_ctrl_i;
		irq_enable_int = m_IE_i;
		debug_csr_save_o = 1'b0;
		debug_cause_o = ibex_defines_DBG_CAUSE_EBREAK;
		debug_mode_n = debug_mode_q;
		perf_tbranch_o = 1'b0;
		perf_jump_o = 1'b0;
		case (ctrl_fsm_cs)
			RESET: begin
				instr_req_o = 1'b0;
				pc_mux_o = ibex_defines_PC_BOOT;
				pc_set_o = 1'b1;
				if (fetch_enable_i)
					ctrl_fsm_ns = BOOT_SET;
			end
			BOOT_SET: begin
				instr_req_o = 1'b1;
				pc_mux_o = ibex_defines_PC_BOOT;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = FIRST_FETCH;
			end
			WAIT_SLEEP: begin
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				ctrl_fsm_ns = SLEEP;
			end
			SLEEP: begin
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (((irq_i || debug_req_i) || debug_mode_q) || debug_single_step_i)
					ctrl_fsm_ns = FIRST_FETCH;
			end
			FIRST_FETCH: begin
				first_fetch_o = 1'b1;
				if (id_ready_i)
					ctrl_fsm_ns = DECODE;
				if (irq_req_ctrl_i && irq_enable_int) begin
					ctrl_fsm_ns = IRQ_TAKEN;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
				end
				if (debug_req_i && !debug_mode_q) begin
					ctrl_fsm_ns = DBG_TAKEN_IF;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
				end
			end
			DECODE: begin
				is_decoding_o = 1'b0;
				case (1'b1)
					debug_req_i && !debug_mode_q: begin
						ctrl_fsm_ns = DBG_TAKEN_ID;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
					end
					((irq_req_ctrl_i && irq_enable_int) && !debug_req_i) && !debug_mode_q: begin
						ctrl_fsm_ns = IRQ_TAKEN;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
					end
					default: begin
						exc_kill_o = (irq_req_ctrl_i & ~instr_multicyle_i) & ~branch_in_id_i;
						if (instr_valid_i) begin
							is_decoding_o = 1'b1;
							if (branch_set_i || jump_set_i) begin
								pc_mux_o = ibex_defines_PC_JUMP;
								pc_set_o = 1'b1;
								perf_tbranch_o = branch_set_i;
								perf_jump_o = jump_set_i;
							end
							else if ((((((mret_insn_i || dret_insn_i) || ecall_insn_i) || pipe_flush_i) || ebrk_insn_i) || illegal_insn_i) || csr_status_i) begin
								ctrl_fsm_ns = FLUSH;
								halt_if_o = 1'b1;
								halt_id_o = 1'b1;
							end
						end
					end
				endcase
				if (debug_single_step_i && !debug_mode_q) begin
					halt_if_o = 1'b1;
					ctrl_fsm_ns = DBG_TAKEN_IF;
				end
			end
			IRQ_TAKEN: begin
				pc_mux_o = ibex_defines_PC_EXCEPTION;
				pc_set_o = 1'b1;
				exc_pc_mux_o = ibex_defines_EXC_PC_IRQ;
				exc_cause_o = sv2v_cast_6({1'b0, irq_id_ctrl_i});
				csr_save_cause_o = 1'b1;
				csr_cause_o = sv2v_cast_6({1'b1, irq_id_ctrl_i});
				csr_save_if_o = 1'b1;
				irq_ack_o = 1'b1;
				exc_ack_o = 1'b1;
				ctrl_fsm_ns = DECODE;
			end
			DBG_TAKEN_IF: begin
				pc_mux_o = ibex_defines_PC_EXCEPTION;
				pc_set_o = 1'b1;
				exc_pc_mux_o = ibex_defines_EXC_PC_DBD;
				csr_save_if_o = 1'b1;
				debug_csr_save_o = 1'b1;
				csr_save_cause_o = 1'b1;
				if (debug_single_step_i)
					debug_cause_o = ibex_defines_DBG_CAUSE_STEP;
				else if (debug_req_i)
					debug_cause_o = ibex_defines_DBG_CAUSE_HALTREQ;
				else if (ebrk_insn_i)
					debug_cause_o = ibex_defines_DBG_CAUSE_EBREAK;
				debug_mode_n = 1'b1;
				ctrl_fsm_ns = DECODE;
			end
			DBG_TAKEN_ID: begin
				pc_mux_o = ibex_defines_PC_EXCEPTION;
				pc_set_o = 1'b1;
				exc_pc_mux_o = ibex_defines_EXC_PC_DBD;
				if (((ebrk_insn_i && debug_ebreakm_i) && !debug_mode_q) || (debug_req_i && !debug_mode_q)) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
					if (debug_req_i)
						debug_cause_o = ibex_defines_DBG_CAUSE_HALTREQ;
					else if (ebrk_insn_i)
						debug_cause_o = ibex_defines_DBG_CAUSE_EBREAK;
				end
				debug_mode_n = 1'b1;
				ctrl_fsm_ns = DECODE;
			end
			FLUSH: begin
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (!pipe_flush_i)
					ctrl_fsm_ns = DECODE;
				else
					ctrl_fsm_ns = WAIT_SLEEP;
				case (1'b1)
					ecall_insn_i: begin
						pc_mux_o = ibex_defines_PC_EXCEPTION;
						pc_set_o = 1'b1;
						csr_save_id_o = 1'b1;
						csr_save_cause_o = 1'b1;
						exc_pc_mux_o = ibex_defines_EXC_PC_ECALL;
						exc_cause_o = ibex_defines_EXC_CAUSE_ECALL_MMODE;
						csr_cause_o = ibex_defines_EXC_CAUSE_ECALL_MMODE;
					end
					illegal_insn_i: begin
						pc_mux_o = ibex_defines_PC_EXCEPTION;
						pc_set_o = 1'b1;
						csr_save_id_o = 1'b1;
						csr_save_cause_o = 1'b1;
						if (debug_mode_q)
							exc_pc_mux_o = ibex_defines_EXC_PC_DBGEXC;
						else
							exc_pc_mux_o = ibex_defines_EXC_PC_ILLINSN;
						exc_cause_o = ibex_defines_EXC_CAUSE_ILLEGAL_INSN;
						csr_cause_o = ibex_defines_EXC_CAUSE_ILLEGAL_INSN;
					end
					mret_insn_i: begin
						pc_mux_o = ibex_defines_PC_ERET;
						pc_set_o = 1'b1;
						csr_restore_mret_id_o = 1'b1;
					end
					dret_insn_i: begin
						pc_mux_o = ibex_defines_PC_DRET;
						pc_set_o = 1'b1;
						debug_mode_n = 1'b0;
						csr_restore_dret_id_o = 1'b1;
					end
					ebrk_insn_i:
						if (debug_mode_q)
							ctrl_fsm_ns = DBG_TAKEN_ID;
						else if (debug_ebreakm_i)
							ctrl_fsm_ns = DBG_TAKEN_ID;
						else begin
							pc_mux_o = ibex_defines_PC_EXCEPTION;
							pc_set_o = 1'b1;
							csr_save_id_o = 1'b1;
							csr_save_cause_o = 1'b1;
							exc_pc_mux_o = ibex_defines_EXC_PC_BREAKPOINT;
							exc_cause_o = ibex_defines_EXC_CAUSE_BREAKPOINT;
							csr_cause_o = ibex_defines_EXC_CAUSE_BREAKPOINT;
						end
					default:
						;
				endcase
			end
			default: begin
				instr_req_o = 1'b0;
				ctrl_fsm_ns = RESET;
			end
		endcase
	end
	assign deassert_we_o = ~is_decoding_o | illegal_insn_i;
	localparam [0:0] ibex_defines_SEL_MISALIGNED = 1;
	localparam [0:0] ibex_defines_SEL_REGFILE = 0;
	assign operand_a_fw_mux_sel_o = (data_misaligned_i ? ibex_defines_SEL_MISALIGNED : ibex_defines_SEL_REGFILE);
	always @(posedge clk or negedge rst_n) begin : UPDATE_REGS
		if (!rst_n) begin
			ctrl_fsm_cs <= RESET;
			debug_mode_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			debug_mode_q <= debug_mode_n;
		end
	end
endmodule

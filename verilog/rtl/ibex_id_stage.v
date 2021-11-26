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

module ibex_id_stage (
	clk,
	rst_n,
	test_en_i,
	fetch_enable_i,
	ctrl_busy_o,
	core_ctrl_firstfetch_o,
	is_decoding_o,
	instr_valid_i,
	instr_rdata_i,
	instr_req_o,
	branch_decision_i,
	clear_instr_valid_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	illegal_c_insn_i,
	is_compressed_i,
	pc_id_i,
	halt_if_o,
	id_ready_o,
	ex_ready_i,
	id_valid_o,
	alu_operator_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	mult_en_ex_o,
	div_en_ex_o,
	multdiv_operator_ex_o,
	multdiv_signed_mode_ex_o,
	multdiv_operand_a_ex_o,
	multdiv_operand_b_ex_o,
	eFPGA_en_o,
	eFPGA_operator_o,
	eFPGA_operand_a_o,
	eFPGA_operand_b_o,
	eFPGA_delay_o,
	csr_access_ex_o,
	csr_op_ex_o,
	csr_cause_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	data_req_ex_o,
	data_we_ex_o,
	data_type_ex_o,
	data_sign_ext_ex_o,
	data_reg_offset_ex_o,
	data_wdata_ex_o,
	data_misaligned_i,
	misaligned_addr_i,
	irq_i,
	irq_id_i,
	m_irq_enable_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	lsu_load_err_i,
	lsu_store_err_i,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	regfile_wdata_lsu_i,
	regfile_wdata_ex_i,
	csr_rdata_i,
	perf_jump_o,
	perf_branch_o,
	perf_tbranch_o
);
	parameter [0:0] RV32M = 1;
	parameter [0:0] RV32E = 0;
	input wire clk;
	input wire rst_n;
	input wire test_en_i;
	input wire fetch_enable_i;
	output wire ctrl_busy_o;
	output wire core_ctrl_firstfetch_o;
	output wire is_decoding_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	input wire branch_decision_i;
	output wire clear_instr_valid_o;
	output wire pc_set_o;
	output wire [2:0] pc_mux_o;
	output wire [2:0] exc_pc_mux_o;
	input wire illegal_c_insn_i;
	input wire is_compressed_i;
	input wire [31:0] pc_id_i;
	output wire halt_if_o;
	output wire id_ready_o;
	input wire ex_ready_i;
	output wire id_valid_o;
	output wire [4:0] alu_operator_ex_o;
	output wire [31:0] alu_operand_a_ex_o;
	output wire [31:0] alu_operand_b_ex_o;
	output wire mult_en_ex_o;
	output wire div_en_ex_o;
	output wire [1:0] multdiv_operator_ex_o;
	output wire [1:0] multdiv_signed_mode_ex_o;
	output wire [31:0] multdiv_operand_a_ex_o;
	output wire [31:0] multdiv_operand_b_ex_o;
	output wire eFPGA_en_o;
	output wire [1:0] eFPGA_operator_o;
	output wire [31:0] eFPGA_operand_a_o;
	output wire [31:0] eFPGA_operand_b_o;
	output wire [3:0] eFPGA_delay_o;
	output wire csr_access_ex_o;
	output wire [1:0] csr_op_ex_o;
	output wire [5:0] csr_cause_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire data_req_ex_o;
	output wire data_we_ex_o;
	output wire [1:0] data_type_ex_o;
	output wire data_sign_ext_ex_o;
	output wire [1:0] data_reg_offset_ex_o;
	output wire [31:0] data_wdata_ex_o;
	input wire data_misaligned_i;
	input wire [31:0] misaligned_addr_i;
	input wire irq_i;
	input wire [4:0] irq_id_i;
	input wire m_irq_enable_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	output wire [5:0] exc_cause_o;
	input wire lsu_load_err_i;
	input wire lsu_store_err_i;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire [31:0] regfile_wdata_lsu_i;
	input wire [31:0] regfile_wdata_ex_i;
	input wire [31:0] csr_rdata_i;
	output wire perf_jump_o;
	output reg perf_branch_o;
	output wire perf_tbranch_o;
	wire [31:0] instr;
	wire deassert_we;
	wire illegal_insn_dec;
	wire illegal_reg_rv32e;
	wire ebrk_insn;
	wire mret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire pipe_flush_dec;
	wire branch_in_id;
	reg branch_set_n;
	reg branch_set_q;
	reg branch_mux_dec;
	reg jump_set;
	reg jump_mux_dec;
	wire jump_in_id;
	reg instr_multicyle;
	reg load_stall;
	reg multdiv_stall;
	reg branch_stall;
	reg jump_stall;
	reg eFPGA_stall;
	wire halt_id;
	reg regfile_we;
	reg select_data_rf;
	wire [31:0] imm_i_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_j_type;
	wire [31:0] zimm_rs1_type;
	wire [31:0] imm_a;
	reg [31:0] imm_b;
	wire irq_req_ctrl;
	wire [4:0] irq_id_ctrl;
	wire exc_ack;
	wire exc_kill;
	wire [4:0] regfile_addr_ra_id;
	wire [4:0] regfile_addr_rb_id;
	wire [4:0] regfile_alu_waddr_id;
	wire regfile_we_id;
	wire [31:0] regfile_data_ra_id;
	wire [31:0] regfile_data_rb_id;
	wire [4:0] alu_operator;
	wire [1:0] alu_op_a_mux_sel;
	wire alu_op_b_mux_sel;
	wire imm_a_mux_sel;
	wire [2:0] imm_b_mux_sel;
	wire mult_int_en;
	wire div_int_en;
	wire multdiv_int_en;
	wire [1:0] multdiv_operator;
	wire [1:0] multdiv_signed_mode;
	wire eFPGA_en;
	wire eFPGA_int_en;
	wire [1:0] eFPGA_operator;
	wire [3:0] eFPGA_delay;
	assign eFPGA_en_o = eFPGA_int_en;
	wire data_we_id;
	wire [1:0] data_type_id;
	wire data_sign_ext_id;
	wire [1:0] data_reg_offset_id;
	wire data_req_id;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_status;
	wire operand_a_fw_mux_sel;
	wire [31:0] operand_a_fw_id;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	assign instr = instr_rdata_i;
	assign imm_i_type = {{20 {instr[31]}}, instr[31:20]};
	assign imm_s_type = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_b_type = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type = {instr[31:12], 12'b000000000000};
	assign imm_j_type = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign zimm_rs1_type = {27'b000000000000000000000000000, instr[19:15]};
	assign regfile_addr_ra_id = instr[19:15];
	assign regfile_addr_rb_id = instr[24:20];
	assign regfile_alu_waddr_id = instr[11:7];
	assign illegal_reg_rv32e = 1'b0;
	assign clear_instr_valid_o = id_ready_o | halt_id;
	localparam [1:0] ibex_defines_OP_A_CURRPC = 1;
	localparam [1:0] ibex_defines_OP_A_IMM = 2;
	localparam [1:0] ibex_defines_OP_A_REGA_OR_FWD = 0;
	always @(*) begin : alu_operand_a_mux
		case (alu_op_a_mux_sel)
			ibex_defines_OP_A_REGA_OR_FWD: alu_operand_a = operand_a_fw_id;
			ibex_defines_OP_A_CURRPC: alu_operand_a = pc_id_i;
			ibex_defines_OP_A_IMM: alu_operand_a = imm_a;
			default: alu_operand_a = operand_a_fw_id;
		endcase
	end
	localparam [0:0] ibex_defines_IMM_A_Z = 0;
	assign imm_a = (imm_a_mux_sel == ibex_defines_IMM_A_Z ? zimm_rs1_type : {32 {1'sb0}});
	localparam [0:0] ibex_defines_SEL_MISALIGNED = 1;
	assign operand_a_fw_id = (operand_a_fw_mux_sel == ibex_defines_SEL_MISALIGNED ? misaligned_addr_i : regfile_data_ra_id);
	localparam [2:0] ibex_defines_IMM_B_B = 2;
	localparam [2:0] ibex_defines_IMM_B_I = 0;
	localparam [2:0] ibex_defines_IMM_B_J = 4;
	localparam [2:0] ibex_defines_IMM_B_PCINCR = 5;
	localparam [2:0] ibex_defines_IMM_B_S = 1;
	localparam [2:0] ibex_defines_IMM_B_U = 3;
	always @(*) begin : immediate_b_mux
		case (imm_b_mux_sel)
			ibex_defines_IMM_B_I: imm_b = imm_i_type;
			ibex_defines_IMM_B_S: imm_b = imm_s_type;
			ibex_defines_IMM_B_B: imm_b = imm_b_type;
			ibex_defines_IMM_B_U: imm_b = imm_u_type;
			ibex_defines_IMM_B_J: imm_b = imm_j_type;
			ibex_defines_IMM_B_PCINCR: imm_b = (is_compressed_i && !data_misaligned_i ? 32'h00000002 : 32'h00000004);
			default: imm_b = imm_i_type;
		endcase
	end
	localparam [0:0] ibex_defines_OP_B_IMM = 1;
	assign alu_operand_b = (alu_op_b_mux_sel == ibex_defines_OP_B_IMM ? imm_b : regfile_data_rb_id);
	reg [31:0] regfile_wdata_mux;
	reg regfile_we_mux;
	reg [4:0] regfile_waddr_mux;
	localparam [0:0] RF_LSU = 0;
	always @(*) begin
		regfile_we_mux = regfile_we;
		regfile_waddr_mux = regfile_alu_waddr_id;
		if (select_data_rf == RF_LSU)
			regfile_wdata_mux = regfile_wdata_lsu_i;
		else if (csr_access)
			regfile_wdata_mux = csr_rdata_i;
		else
			regfile_wdata_mux = regfile_wdata_ex_i;
	end
	ibex_register_file #(.RV32E(RV32E)) registers_i(
		.clk(clk),
		.rst_n(rst_n),
		.test_en_i(test_en_i),
		.raddr_a_i(regfile_addr_ra_id),
		.rdata_a_o(regfile_data_ra_id),
		.raddr_b_i(regfile_addr_rb_id),
		.rdata_b_o(regfile_data_rb_id),
		.waddr_a_i(regfile_waddr_mux),
		.wdata_a_i(regfile_wdata_mux),
		.we_a_i(regfile_we_mux)
	);
	assign multdiv_int_en = mult_int_en | div_int_en;
	ibex_decoder #(.RV32M(RV32M)) decoder_i(
		.deassert_we_i(deassert_we),
		.data_misaligned_i(data_misaligned_i),
		.branch_mux_i(branch_mux_dec),
		.jump_mux_i(jump_mux_dec),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn),
		.mret_insn_o(mret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.ecall_insn_o(ecall_insn_dec),
		.pipe_flush_o(pipe_flush_dec),
		.instr_rdata_i(instr),
		.illegal_c_insn_i(illegal_c_insn_i),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel),
		.mult_int_en_o(mult_int_en),
		.div_int_en_o(div_int_en),
		.multdiv_operator_o(multdiv_operator),
		.multdiv_signed_mode_o(multdiv_signed_mode),
		.regfile_we_o(regfile_we_id),
		.csr_access_o(csr_access),
		.csr_op_o(csr_op),
		.csr_status_o(csr_status),
		.data_req_o(data_req_id),
		.data_we_o(data_we_id),
		.data_type_o(data_type_id),
		.data_sign_extension_o(data_sign_ext_id),
		.data_reg_offset_o(data_reg_offset_id),
		.jump_in_id_o(jump_in_id),
		.branch_in_id_o(branch_in_id),
		.eFPGA_operator_o(eFPGA_operator),
		.eFPGA_int_en_o(eFPGA_int_en),
		.eFPGA_delay_o(eFPGA_delay)
	);
	assign eFPGA_operator_o = eFPGA_operator;
	assign eFPGA_delay_o = eFPGA_delay;
	ibex_controller controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.fetch_enable_i(fetch_enable_i),
		.ctrl_busy_o(ctrl_busy_o),
		.first_fetch_o(core_ctrl_firstfetch_o),
		.is_decoding_o(is_decoding_o),
		.deassert_we_o(deassert_we),
		.illegal_insn_i(illegal_insn_dec | illegal_reg_rv32e),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.pipe_flush_i(pipe_flush_dec),
		.ebrk_insn_i(ebrk_insn),
		.csr_status_i(csr_status),
		.instr_valid_i(instr_valid_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.data_misaligned_i(data_misaligned_i),
		.branch_in_id_i(branch_in_id),
		.branch_set_i(branch_set_q),
		.jump_set_i(jump_set),
		.instr_multicyle_i(instr_multicyle),
		.irq_i(irq_i),
		.irq_req_ctrl_i(irq_req_ctrl),
		.irq_id_ctrl_i(irq_id_ctrl),
		.m_IE_i(m_irq_enable_i),
		.irq_ack_o(irq_ack_o),
		.irq_id_o(irq_id_o),
		.exc_ack_o(exc_ack),
		.exc_kill_o(exc_kill),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_cause_o(csr_cause_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.operand_a_fw_mux_sel_o(operand_a_fw_mux_sel),
		.halt_if_o(halt_if_o),
		.halt_id_o(halt_id),
		.id_ready_i(id_ready_o),
		.perf_jump_o(perf_jump_o),
		.perf_tbranch_o(perf_tbranch_o)
	);
	ibex_int_controller int_controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.irq_req_ctrl_o(irq_req_ctrl),
		.irq_id_ctrl_o(irq_id_ctrl),
		.ctrl_ack_i(exc_ack),
		.ctrl_kill_i(exc_kill),
		.irq_i(irq_i),
		.irq_id_i(irq_id_i),
		.m_IE_i(m_irq_enable_i)
	);
	assign data_we_ex_o = data_we_id;
	assign data_type_ex_o = data_type_id;
	assign data_sign_ext_ex_o = data_sign_ext_id;
	assign data_wdata_ex_o = regfile_data_rb_id;
	assign data_req_ex_o = data_req_id;
	assign data_reg_offset_ex_o = data_reg_offset_id;
	assign alu_operator_ex_o = alu_operator;
	assign alu_operand_a_ex_o = alu_operand_a;
	assign alu_operand_b_ex_o = alu_operand_b;
	assign csr_access_ex_o = csr_access;
	assign csr_op_ex_o = csr_op;
	assign mult_en_ex_o = mult_int_en;
	assign div_en_ex_o = div_int_en;
	assign multdiv_operator_ex_o = multdiv_operator;
	assign multdiv_signed_mode_ex_o = multdiv_signed_mode;
	assign multdiv_operand_a_ex_o = regfile_data_ra_id;
	assign multdiv_operand_b_ex_o = regfile_data_rb_id;
	assign eFPGA_operand_a_o = regfile_data_ra_id;
	assign eFPGA_operand_b_o = regfile_data_rb_id;
	reg id_wb_fsm_cs;
	reg id_wb_fsm_ns;
	localparam [0:0] IDLE = 0;
	always @(posedge clk or negedge rst_n) begin : EX_WB_Pipeline_Register
		if (!rst_n) begin
			id_wb_fsm_cs <= IDLE;
			branch_set_q <= 1'b0;
		end
		else begin
			id_wb_fsm_cs <= id_wb_fsm_ns;
			branch_set_q <= branch_set_n;
		end
	end
	localparam [0:0] RF_EX = 1;
	localparam [0:0] WAIT_MULTICYCLE = 1;
	always @(*) begin
		id_wb_fsm_ns = id_wb_fsm_cs;
		regfile_we = regfile_we_id;
		load_stall = 1'b0;
		multdiv_stall = 1'b0;
		eFPGA_stall = 1'b0;
		jump_stall = 1'b0;
		branch_stall = 1'b0;
		select_data_rf = RF_EX;
		instr_multicyle = 1'b0;
		branch_set_n = 1'b0;
		branch_mux_dec = 1'b0;
		jump_set = 1'b0;
		jump_mux_dec = 1'b0;
		perf_branch_o = 1'b0;
		case (id_wb_fsm_cs)
			IDLE: begin
				jump_mux_dec = 1'b1;
				branch_mux_dec = 1'b1;
				case (1'b1)
					data_req_id: begin
						regfile_we = 1'b0;
						id_wb_fsm_ns = WAIT_MULTICYCLE;
						load_stall = 1'b1;
						instr_multicyle = 1'b1;
					end
					branch_in_id: begin
						id_wb_fsm_ns = (branch_decision_i ? WAIT_MULTICYCLE : IDLE);
						branch_stall = branch_decision_i;
						instr_multicyle = branch_decision_i;
						branch_set_n = branch_decision_i;
						perf_branch_o = 1'b1;
					end
					multdiv_int_en: begin
						regfile_we = 1'b0;
						id_wb_fsm_ns = WAIT_MULTICYCLE;
						multdiv_stall = 1'b1;
						instr_multicyle = 1'b1;
					end
					eFPGA_int_en: begin
						regfile_we = 1'b0;
						id_wb_fsm_ns = WAIT_MULTICYCLE;
						eFPGA_stall = 1'b1;
						instr_multicyle = 1'b1;
					end
					jump_in_id: begin
						regfile_we = 1'b0;
						id_wb_fsm_ns = WAIT_MULTICYCLE;
						jump_stall = 1'b1;
						instr_multicyle = 1'b1;
						jump_set = 1'b1;
					end
					default:
						;
				endcase
			end
			WAIT_MULTICYCLE:
				if (ex_ready_i) begin
					regfile_we = regfile_we_id;
					id_wb_fsm_ns = IDLE;
					load_stall = 1'b0;
					multdiv_stall = 1'b0;
					eFPGA_stall = 1'b0;
					select_data_rf = (data_req_id ? RF_LSU : RF_EX);
				end
				else begin
					regfile_we = 1'b0;
					instr_multicyle = 1'b1;
					case (1'b1)
						data_req_id: load_stall = 1'b1;
						multdiv_int_en: multdiv_stall = 1'b1;
						eFPGA_int_en: eFPGA_stall = 1'b1;
						default:
							;
					endcase
				end
			default:
				;
		endcase
	end
	assign id_ready_o = (((~load_stall & ~branch_stall) & ~jump_stall) & ~multdiv_stall) & ~eFPGA_stall;
	assign id_valid_o = ~halt_id & id_ready_o;
endmodule

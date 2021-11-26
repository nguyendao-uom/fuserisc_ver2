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

module ibex_decoder (
	deassert_we_i,
	data_misaligned_i,
	branch_mux_i,
	jump_mux_i,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	dret_insn_o,
	ecall_insn_o,
	pipe_flush_o,
	instr_rdata_i,
	illegal_c_insn_i,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	mult_int_en_o,
	div_int_en_o,
	multdiv_operator_o,
	multdiv_signed_mode_o,
	regfile_we_o,
	csr_access_o,
	csr_op_o,
	csr_status_o,
	data_req_o,
	data_we_o,
	data_type_o,
	data_sign_extension_o,
	data_reg_offset_o,
	jump_in_id_o,
	branch_in_id_o,
	eFPGA_operator_o,
	eFPGA_int_en_o,
	eFPGA_delay_o
);
	parameter [0:0] RV32M = 1;
	input wire deassert_we_i;
	input wire data_misaligned_i;
	input wire branch_mux_i;
	input wire jump_mux_i;
	output reg illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg dret_insn_o;
	output reg ecall_insn_o;
	output reg pipe_flush_o;
	input wire [31:0] instr_rdata_i;
	input wire illegal_c_insn_i;
	output reg [4:0] alu_operator_o;
	output reg [1:0] alu_op_a_mux_sel_o;
	output reg alu_op_b_mux_sel_o;
	output reg imm_a_mux_sel_o;
	output reg [2:0] imm_b_mux_sel_o;
	output wire mult_int_en_o;
	output wire div_int_en_o;
	output reg [1:0] multdiv_operator_o;
	output reg [1:0] multdiv_signed_mode_o;
	output wire regfile_we_o;
	output reg csr_access_o;
	output wire [1:0] csr_op_o;
	output reg csr_status_o;
	output wire data_req_o;
	output reg data_we_o;
	output reg [1:0] data_type_o;
	output reg data_sign_extension_o;
	output reg [1:0] data_reg_offset_o;
	output wire jump_in_id_o;
	output wire branch_in_id_o;
	output reg [1:0] eFPGA_operator_o;
	output wire eFPGA_int_en_o;
	output reg [3:0] eFPGA_delay_o;
	reg regfile_we;
	reg data_req;
	reg mult_int_en;
	reg div_int_en;
	reg branch_in_id;
	reg jump_in_id;
	reg eFPGA_int_en;
	reg [1:0] csr_op;
	reg csr_illegal;
	reg [6:0] opcode;
	localparam [4:0] ibex_defines_ALU_ADD = 0;
	localparam [4:0] ibex_defines_ALU_AND = 4;
	localparam [4:0] ibex_defines_ALU_EQ = 16;
	localparam [4:0] ibex_defines_ALU_GE = 14;
	localparam [4:0] ibex_defines_ALU_GEU = 15;
	localparam [4:0] ibex_defines_ALU_LT = 8;
	localparam [4:0] ibex_defines_ALU_LTU = 9;
	localparam [4:0] ibex_defines_ALU_NE = 17;
	localparam [4:0] ibex_defines_ALU_OR = 3;
	localparam [4:0] ibex_defines_ALU_SLL = 7;
	localparam [4:0] ibex_defines_ALU_SLT = 18;
	localparam [4:0] ibex_defines_ALU_SLTU = 19;
	localparam [4:0] ibex_defines_ALU_SRA = 5;
	localparam [4:0] ibex_defines_ALU_SRL = 6;
	localparam [4:0] ibex_defines_ALU_SUB = 1;
	localparam [4:0] ibex_defines_ALU_XOR = 2;
	localparam [11:0] ibex_defines_CSR_DCSR = 12'h7b0;
	localparam [11:0] ibex_defines_CSR_DPC = 12'h7b1;
	localparam [11:0] ibex_defines_CSR_DSCRATCH0 = 12'h7b2;
	localparam [11:0] ibex_defines_CSR_DSCRATCH1 = 12'h7b3;
	localparam [11:0] ibex_defines_CSR_MSTATUS = 12'h300;
	localparam [1:0] ibex_defines_CSR_OP_CLEAR = 3;
	localparam [1:0] ibex_defines_CSR_OP_NONE = 0;
	localparam [1:0] ibex_defines_CSR_OP_SET = 2;
	localparam [1:0] ibex_defines_CSR_OP_WRITE = 1;
	localparam [0:0] ibex_defines_IMM_A_Z = 0;
	localparam [0:0] ibex_defines_IMM_A_ZERO = 1;
	localparam [2:0] ibex_defines_IMM_B_B = 2;
	localparam [2:0] ibex_defines_IMM_B_I = 0;
	localparam [2:0] ibex_defines_IMM_B_J = 4;
	localparam [2:0] ibex_defines_IMM_B_PCINCR = 5;
	localparam [2:0] ibex_defines_IMM_B_S = 1;
	localparam [2:0] ibex_defines_IMM_B_U = 3;
	localparam [1:0] ibex_defines_MD_OP_DIV = 2;
	localparam [1:0] ibex_defines_MD_OP_MULH = 1;
	localparam [1:0] ibex_defines_MD_OP_MULL = 0;
	localparam [1:0] ibex_defines_MD_OP_REM = 3;
	localparam [6:0] ibex_defines_OPCODE_AUIPC = 7'h17;
	localparam [6:0] ibex_defines_OPCODE_BRANCH = 7'h63;
	localparam [6:0] ibex_defines_OPCODE_FENCE = 7'h0f;
	localparam [6:0] ibex_defines_OPCODE_JAL = 7'h6f;
	localparam [6:0] ibex_defines_OPCODE_JALR = 7'h67;
	localparam [6:0] ibex_defines_OPCODE_LOAD = 7'h03;
	localparam [6:0] ibex_defines_OPCODE_LUI = 7'h37;
	localparam [6:0] ibex_defines_OPCODE_OP = 7'h33;
	localparam [6:0] ibex_defines_OPCODE_OPIMM = 7'h13;
	localparam [6:0] ibex_defines_OPCODE_STORE = 7'h23;
	localparam [6:0] ibex_defines_OPCODE_SYSTEM = 7'h73;
	localparam [6:0] ibex_defines_OPCODE_eFPGA = 7'h0b;
	localparam [1:0] ibex_defines_OP_A_CURRPC = 1;
	localparam [1:0] ibex_defines_OP_A_IMM = 2;
	localparam [1:0] ibex_defines_OP_A_REGA_OR_FWD = 0;
	localparam [0:0] ibex_defines_OP_B_IMM = 1;
	localparam [0:0] ibex_defines_OP_B_REGB_OR_FWD = 0;
	always @(*) begin
		jump_in_id = 1'b0;
		branch_in_id = 1'b0;
		alu_operator_o = ibex_defines_ALU_SLTU;
		alu_op_a_mux_sel_o = ibex_defines_OP_A_REGA_OR_FWD;
		alu_op_b_mux_sel_o = ibex_defines_OP_B_REGB_OR_FWD;
		imm_a_mux_sel_o = ibex_defines_IMM_A_ZERO;
		imm_b_mux_sel_o = ibex_defines_IMM_B_I;
		mult_int_en = 1'b0;
		div_int_en = 1'b0;
		multdiv_operator_o = ibex_defines_MD_OP_MULL;
		multdiv_signed_mode_o = 2'b00;
		eFPGA_int_en = 1'b0;
		eFPGA_operator_o = 2'b00;
		regfile_we = 1'b0;
		csr_access_o = 1'b0;
		csr_status_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = ibex_defines_CSR_OP_NONE;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 1'b0;
		data_reg_offset_o = 2'b00;
		data_req = 1'b0;
		illegal_insn_o = 1'b0;
		ebrk_insn_o = 1'b0;
		mret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		pipe_flush_o = 1'b0;
		opcode = instr_rdata_i[6:0];
		case (opcode)
			ibex_defines_OPCODE_JAL: begin
				jump_in_id = 1'b1;
				if (jump_mux_i) begin
					alu_op_a_mux_sel_o = ibex_defines_OP_A_CURRPC;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_b_mux_sel_o = ibex_defines_IMM_B_J;
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b0;
				end
				else begin
					alu_op_a_mux_sel_o = ibex_defines_OP_A_CURRPC;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_b_mux_sel_o = ibex_defines_IMM_B_PCINCR;
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b1;
				end
			end
			ibex_defines_OPCODE_JALR: begin
				jump_in_id = 1'b1;
				if (jump_mux_i) begin
					alu_op_a_mux_sel_o = ibex_defines_OP_A_REGA_OR_FWD;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_b_mux_sel_o = ibex_defines_IMM_B_I;
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b0;
				end
				else begin
					alu_op_a_mux_sel_o = ibex_defines_OP_A_CURRPC;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_b_mux_sel_o = ibex_defines_IMM_B_PCINCR;
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b1;
				end
				if (instr_rdata_i[14:12] != 3'b000) begin
					jump_in_id = 1'b0;
					regfile_we = 1'b0;
					illegal_insn_o = 1'b1;
				end
			end
			ibex_defines_OPCODE_BRANCH: begin
				branch_in_id = 1'b1;
				if (branch_mux_i)
					case (instr_rdata_i[14:12])
						3'b000: alu_operator_o = ibex_defines_ALU_EQ;
						3'b001: alu_operator_o = ibex_defines_ALU_NE;
						3'b100: alu_operator_o = ibex_defines_ALU_LT;
						3'b101: alu_operator_o = ibex_defines_ALU_GE;
						3'b110: alu_operator_o = ibex_defines_ALU_LTU;
						3'b111: alu_operator_o = ibex_defines_ALU_GEU;
						default: illegal_insn_o = 1'b1;
					endcase
				else begin
					alu_op_a_mux_sel_o = ibex_defines_OP_A_CURRPC;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_b_mux_sel_o = ibex_defines_IMM_B_B;
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b0;
				end
			end
			ibex_defines_OPCODE_STORE: begin
				data_req = 1'b1;
				data_we_o = 1'b1;
				alu_operator_o = ibex_defines_ALU_ADD;
				if (!instr_rdata_i[14]) begin
					imm_b_mux_sel_o = ibex_defines_IMM_B_S;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
				end
				else begin
					data_req = 1'b0;
					data_we_o = 1'b0;
					illegal_insn_o = 1'b1;
				end
				case (instr_rdata_i[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: data_type_o = 2'b00;
					default: begin
						data_req = 1'b0;
						data_we_o = 1'b0;
						illegal_insn_o = 1'b1;
					end
				endcase
			end
			ibex_defines_OPCODE_LOAD: begin
				data_req = 1'b1;
				regfile_we = 1'b1;
				data_type_o = 2'b00;
				alu_operator_o = ibex_defines_ALU_ADD;
				alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
				imm_b_mux_sel_o = ibex_defines_IMM_B_I;
				data_sign_extension_o = ~instr_rdata_i[14];
				case (instr_rdata_i[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: data_type_o = 2'b00;
					default: data_type_o = 2'b00;
				endcase
				if (instr_rdata_i[14:12] == 3'b111) begin
					alu_op_b_mux_sel_o = ibex_defines_OP_B_REGB_OR_FWD;
					data_sign_extension_o = ~instr_rdata_i[30];
					case (instr_rdata_i[31:25])
						7'b0000000, 7'b0100000: data_type_o = 2'b10;
						7'b0001000, 7'b0101000: data_type_o = 2'b01;
						7'b0010000: data_type_o = 2'b00;
						default: illegal_insn_o = 1'b1;
					endcase
				end
				if (instr_rdata_i[14:12] == 3'b011)
					illegal_insn_o = 1'b1;
			end
			ibex_defines_OPCODE_LUI: begin
				alu_op_a_mux_sel_o = ibex_defines_OP_A_IMM;
				alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
				imm_a_mux_sel_o = ibex_defines_IMM_A_ZERO;
				imm_b_mux_sel_o = ibex_defines_IMM_B_U;
				alu_operator_o = ibex_defines_ALU_ADD;
				regfile_we = 1'b1;
			end
			ibex_defines_OPCODE_AUIPC: begin
				alu_op_a_mux_sel_o = ibex_defines_OP_A_CURRPC;
				alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
				imm_b_mux_sel_o = ibex_defines_IMM_B_U;
				alu_operator_o = ibex_defines_ALU_ADD;
				regfile_we = 1'b1;
			end
			ibex_defines_OPCODE_OPIMM: begin
				alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
				imm_b_mux_sel_o = ibex_defines_IMM_B_I;
				regfile_we = 1'b1;
				case (instr_rdata_i[14:12])
					3'b000: alu_operator_o = ibex_defines_ALU_ADD;
					3'b010: alu_operator_o = ibex_defines_ALU_SLT;
					3'b011: alu_operator_o = ibex_defines_ALU_SLTU;
					3'b100: alu_operator_o = ibex_defines_ALU_XOR;
					3'b110: alu_operator_o = ibex_defines_ALU_OR;
					3'b111: alu_operator_o = ibex_defines_ALU_AND;
					3'b001: begin
						alu_operator_o = ibex_defines_ALU_SLL;
						if (instr_rdata_i[31:25] != 7'b0000000)
							illegal_insn_o = 1'b1;
					end
					3'b101:
						if (instr_rdata_i[31:25] == 7'b0000000)
							alu_operator_o = ibex_defines_ALU_SRL;
						else if (instr_rdata_i[31:25] == 7'b0100000)
							alu_operator_o = ibex_defines_ALU_SRA;
						else
							illegal_insn_o = 1'b1;
					default:
						;
				endcase
			end
			ibex_defines_OPCODE_OP: begin
				regfile_we = 1'b1;
				if (instr_rdata_i[31])
					illegal_insn_o = 1'b1;
				else if (!instr_rdata_i[28])
					case ({instr_rdata_i[30:25], instr_rdata_i[14:12]})
						9'b000000000: alu_operator_o = ibex_defines_ALU_ADD;
						9'b100000000: alu_operator_o = ibex_defines_ALU_SUB;
						9'b000000010: alu_operator_o = ibex_defines_ALU_SLT;
						9'b000000011: alu_operator_o = ibex_defines_ALU_SLTU;
						9'b000000100: alu_operator_o = ibex_defines_ALU_XOR;
						9'b000000110: alu_operator_o = ibex_defines_ALU_OR;
						9'b000000111: alu_operator_o = ibex_defines_ALU_AND;
						9'b000000001: alu_operator_o = ibex_defines_ALU_SLL;
						9'b000000101: alu_operator_o = ibex_defines_ALU_SRL;
						9'b100000101: alu_operator_o = ibex_defines_ALU_SRA;
						9'b000001000: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_MULL;
							mult_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001001: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_MULH;
							mult_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001010: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_MULH;
							mult_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b01;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001011: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_MULH;
							mult_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001100: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_DIV;
							div_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001101: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_DIV;
							div_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001110: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_REM;
							div_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						9'b000001111: begin
							alu_operator_o = ibex_defines_ALU_ADD;
							multdiv_operator_o = ibex_defines_MD_OP_REM;
							div_int_en = 1'b1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn_o = (RV32M ? 1'b0 : 1'b1);
						end
						default: illegal_insn_o = 1'b1;
					endcase
			end
			ibex_defines_OPCODE_eFPGA: begin
				regfile_we = 1'b1;
				eFPGA_operator_o = instr_rdata_i[13:12];
				eFPGA_delay_o = instr_rdata_i[28:25];
				eFPGA_int_en = 1'b1;
			end
			ibex_defines_OPCODE_FENCE:
				if (instr_rdata_i[14:12] == 3'b000) begin
					alu_operator_o = ibex_defines_ALU_ADD;
					regfile_we = 1'b0;
				end
				else
					illegal_insn_o = 1'b1;
			ibex_defines_OPCODE_SYSTEM:
				if (instr_rdata_i[14:12] == 3'b000)
					case (instr_rdata_i[31:20])
						12'h000: ecall_insn_o = 1'b1;
						12'h001: ebrk_insn_o = 1'b1;
						12'h302: mret_insn_o = 1'b1;
						12'h7b2: dret_insn_o = 1'b1;
						12'h105: pipe_flush_o = 1'b1;
						default: illegal_insn_o = 1'b1;
					endcase
				else begin
					csr_access_o = 1'b1;
					regfile_we = 1'b1;
					alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
					imm_a_mux_sel_o = ibex_defines_IMM_A_Z;
					imm_b_mux_sel_o = ibex_defines_IMM_B_I;
					if (instr_rdata_i[14])
						alu_op_a_mux_sel_o = ibex_defines_OP_A_IMM;
					else
						alu_op_a_mux_sel_o = ibex_defines_OP_A_REGA_OR_FWD;
					case (instr_rdata_i[13:12])
						2'b01: csr_op = ibex_defines_CSR_OP_WRITE;
						2'b10: csr_op = ibex_defines_CSR_OP_SET;
						2'b11: csr_op = ibex_defines_CSR_OP_CLEAR;
						default: csr_illegal = 1'b1;
					endcase
					if (!csr_illegal)
						if (((((instr_rdata_i[31:20] == ibex_defines_CSR_MSTATUS) || (instr_rdata_i[31:20] == ibex_defines_CSR_DCSR)) || (instr_rdata_i[31:20] == ibex_defines_CSR_DPC)) || (instr_rdata_i[31:20] == ibex_defines_CSR_DSCRATCH0)) || (instr_rdata_i[31:20] == ibex_defines_CSR_DSCRATCH1))
							csr_status_o = 1'b1;
					illegal_insn_o = csr_illegal;
				end
			default: illegal_insn_o = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn_o = 1'b1;
		if (data_misaligned_i) begin
			alu_op_a_mux_sel_o = ibex_defines_OP_A_REGA_OR_FWD;
			alu_op_b_mux_sel_o = ibex_defines_OP_B_IMM;
			imm_b_mux_sel_o = ibex_defines_IMM_B_PCINCR;
			regfile_we = 1'b0;
		end
	end
	assign regfile_we_o = (deassert_we_i ? 1'b0 : regfile_we);
	assign mult_int_en_o = (RV32M ? (deassert_we_i ? 1'b0 : mult_int_en) : 1'b0);
	assign div_int_en_o = (RV32M ? (deassert_we_i ? 1'b0 : div_int_en) : 1'b0);
	assign data_req_o = (deassert_we_i ? 1'b0 : data_req);
	assign csr_op_o = (deassert_we_i ? ibex_defines_CSR_OP_NONE : csr_op);
	assign jump_in_id_o = (deassert_we_i ? 1'b0 : jump_in_id);
	assign branch_in_id_o = (deassert_we_i ? 1'b0 : branch_in_id);
	assign eFPGA_int_en_o = (deassert_we_i ? 1'b0 : eFPGA_int_en);
endmodule

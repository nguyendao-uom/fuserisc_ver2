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

module ibex_alu (
	operator_i,
	operand_a_i,
	operand_b_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_en_i,
	adder_result_o,
	adder_result_ext_o,
	result_o,
	comparison_result_o,
	is_equal_result_o
);
	input wire [4:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire [32:0] multdiv_operand_a_i;
	input wire [32:0] multdiv_operand_b_i;
	input wire multdiv_en_i;
	output wire [31:0] adder_result_o;
	output wire [33:0] adder_result_ext_o;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire is_equal_result_o;
	wire [31:0] operand_a_rev;
	wire [32:0] operand_b_neg;
	generate
		genvar k;
		for (k = 0; k < 32; k = k + 1) begin : gen_revloop
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	reg adder_op_b_negate;
	wire [32:0] adder_in_a;
	wire [32:0] adder_in_b;
	wire [31:0] adder_result;
	localparam [4:0] ibex_defines_ALU_EQ = 16;
	localparam [4:0] ibex_defines_ALU_GE = 14;
	localparam [4:0] ibex_defines_ALU_GEU = 15;
	localparam [4:0] ibex_defines_ALU_GT = 12;
	localparam [4:0] ibex_defines_ALU_GTU = 13;
	localparam [4:0] ibex_defines_ALU_LE = 10;
	localparam [4:0] ibex_defines_ALU_LEU = 11;
	localparam [4:0] ibex_defines_ALU_LT = 8;
	localparam [4:0] ibex_defines_ALU_LTU = 9;
	localparam [4:0] ibex_defines_ALU_NE = 17;
	localparam [4:0] ibex_defines_ALU_SLET = 20;
	localparam [4:0] ibex_defines_ALU_SLETU = 21;
	localparam [4:0] ibex_defines_ALU_SLT = 18;
	localparam [4:0] ibex_defines_ALU_SLTU = 19;
	localparam [4:0] ibex_defines_ALU_SUB = 1;
	always @(*) begin
		adder_op_b_negate = 1'b0;
		case (operator_i)
			ibex_defines_ALU_SUB, ibex_defines_ALU_EQ, ibex_defines_ALU_NE, ibex_defines_ALU_GTU, ibex_defines_ALU_GEU, ibex_defines_ALU_LTU, ibex_defines_ALU_LEU, ibex_defines_ALU_GT, ibex_defines_ALU_GE, ibex_defines_ALU_LT, ibex_defines_ALU_LE, ibex_defines_ALU_SLT, ibex_defines_ALU_SLTU, ibex_defines_ALU_SLET, ibex_defines_ALU_SLETU: adder_op_b_negate = 1'b1;
			default:
				;
		endcase
	end
	assign adder_in_a = (multdiv_en_i ? multdiv_operand_a_i : {operand_a_i, 1'b1});
	assign operand_b_neg = {operand_b_i, 1'b0} ^ {33 {adder_op_b_negate}};
	assign adder_in_b = (multdiv_en_i ? multdiv_operand_b_i : operand_b_neg);
	assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
	assign adder_result = adder_result_ext_o[32:1];
	assign adder_result_o = adder_result;
	wire shift_left;
	wire shift_arithmetic;
	wire [4:0] shift_amt;
	wire [31:0] shift_op_a;
	wire [31:0] shift_result;
	wire [31:0] shift_right_result;
	wire [31:0] shift_left_result;
	assign shift_amt = operand_b_i[4:0];
	localparam [4:0] ibex_defines_ALU_SLL = 7;
	assign shift_left = operator_i == ibex_defines_ALU_SLL;
	localparam [4:0] ibex_defines_ALU_SRA = 5;
	assign shift_arithmetic = operator_i == ibex_defines_ALU_SRA;
	assign shift_op_a = (shift_left ? operand_a_rev : operand_a_i);
	wire [32:0] shift_op_a_32;
	assign shift_op_a_32 = {shift_arithmetic & shift_op_a[31], shift_op_a};
	wire signed [32:0] shift_right_result_signed;
	assign shift_right_result_signed = $signed(shift_op_a_32) >>> shift_amt[4:0];
	assign shift_right_result = shift_right_result_signed[31:0];
	generate
		genvar j;
		for (j = 0; j < 32; j = j + 1) begin : gen_resrevloop
			assign shift_left_result[j] = shift_right_result[31 - j];
		end
	endgenerate
	assign shift_result = (shift_left ? shift_left_result : shift_right_result);
	wire is_equal;
	reg is_greater_equal;
	reg cmp_signed;
	always @(*) begin
		cmp_signed = 1'b0;
		case (operator_i)
			ibex_defines_ALU_GT, ibex_defines_ALU_GE, ibex_defines_ALU_LT, ibex_defines_ALU_LE, ibex_defines_ALU_SLT, ibex_defines_ALU_SLET: cmp_signed = 1'b1;
			default:
				;
		endcase
	end
	assign is_equal = adder_result == 32'b00000000000000000000000000000000;
	assign is_equal_result_o = is_equal;
	always @(*)
		if ((operand_a_i[31] ^ operand_b_i[31]) == 1'b0)
			is_greater_equal = adder_result[31] == 1'b0;
		else
			is_greater_equal = operand_a_i[31] ^ cmp_signed;
	reg cmp_result;
	always @(*) begin
		cmp_result = is_equal;
		case (operator_i)
			ibex_defines_ALU_EQ: cmp_result = is_equal;
			ibex_defines_ALU_NE: cmp_result = ~is_equal;
			ibex_defines_ALU_GT, ibex_defines_ALU_GTU: cmp_result = is_greater_equal & ~is_equal;
			ibex_defines_ALU_GE, ibex_defines_ALU_GEU: cmp_result = is_greater_equal;
			ibex_defines_ALU_LT, ibex_defines_ALU_SLT, ibex_defines_ALU_LTU, ibex_defines_ALU_SLTU: cmp_result = ~is_greater_equal;
			ibex_defines_ALU_SLET, ibex_defines_ALU_SLETU, ibex_defines_ALU_LE, ibex_defines_ALU_LEU: cmp_result = ~is_greater_equal | is_equal;
			default:
				;
		endcase
	end
	assign comparison_result_o = cmp_result;
	localparam [4:0] ibex_defines_ALU_ADD = 0;
	localparam [4:0] ibex_defines_ALU_AND = 4;
	localparam [4:0] ibex_defines_ALU_OR = 3;
	localparam [4:0] ibex_defines_ALU_SRL = 6;
	localparam [4:0] ibex_defines_ALU_XOR = 2;
	always @(*) begin
		result_o = {32 {1'sb0}};
		case (operator_i)
			ibex_defines_ALU_AND: result_o = operand_a_i & operand_b_i;
			ibex_defines_ALU_OR: result_o = operand_a_i | operand_b_i;
			ibex_defines_ALU_XOR: result_o = operand_a_i ^ operand_b_i;
			ibex_defines_ALU_ADD, ibex_defines_ALU_SUB: result_o = adder_result;
			ibex_defines_ALU_SLL, ibex_defines_ALU_SRL, ibex_defines_ALU_SRA: result_o = shift_result;
			ibex_defines_ALU_EQ, ibex_defines_ALU_NE, ibex_defines_ALU_GTU, ibex_defines_ALU_GEU, ibex_defines_ALU_LTU, ibex_defines_ALU_LEU, ibex_defines_ALU_GT, ibex_defines_ALU_GE, ibex_defines_ALU_LT, ibex_defines_ALU_LE, ibex_defines_ALU_SLT, ibex_defines_ALU_SLTU, ibex_defines_ALU_SLET, ibex_defines_ALU_SLETU: result_o = {31'h00000000, cmp_result};
			default:
				;
		endcase
	end
endmodule

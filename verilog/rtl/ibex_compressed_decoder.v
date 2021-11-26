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

module ibex_compressed_decoder (
	instr_i,
	instr_o,
	is_compressed_o,
	illegal_instr_o
);
	input wire [31:0] instr_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output reg illegal_instr_o;
	localparam [6:0] ibex_defines_OPCODE_BRANCH = 7'h63;
	localparam [6:0] ibex_defines_OPCODE_JAL = 7'h6f;
	localparam [6:0] ibex_defines_OPCODE_JALR = 7'h67;
	localparam [6:0] ibex_defines_OPCODE_LOAD = 7'h03;
	localparam [6:0] ibex_defines_OPCODE_LUI = 7'h37;
	localparam [6:0] ibex_defines_OPCODE_OP = 7'h33;
	localparam [6:0] ibex_defines_OPCODE_OPIMM = 7'h13;
	localparam [6:0] ibex_defines_OPCODE_STORE = 7'h23;
	always @(*) begin
		illegal_instr_o = 1'b0;
		instr_o = {32 {1'sb0}};
		case (instr_i[1:0])
			2'b00:
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 2'b00, 5'h02, 3'b000, 2'b01, instr_i[4:2], {ibex_defines_OPCODE_OPIMM}};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 2'b00, 2'b01, instr_i[9:7], 3'b010, 2'b01, instr_i[4:2], {ibex_defines_OPCODE_LOAD}};
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, {ibex_defines_OPCODE_STORE}};
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				case (instr_i[15:13])
					3'b000: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], {ibex_defines_OPCODE_OPIMM}};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], {ibex_defines_OPCODE_JAL}};
					3'b010: begin
						instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b00000, 3'b000, instr_i[11:7], {ibex_defines_OPCODE_OPIMM}};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b011: begin
						instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], {ibex_defines_OPCODE_LUI}};
						if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 4'b0000, 5'h02, 3'b000, 5'h02, {ibex_defines_OPCODE_OPIMM}};
						else if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						case (instr_i[11:10])
							2'b00, 2'b01: begin
								instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 3'b101, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OPIMM}};
								if (instr_i[12] == 1'b1)
									illegal_instr_o = 1'b1;
								if (instr_i[6:2] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OPIMM}};
							2'b11:
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 3'b000, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OP}};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 3'b100, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OP}};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 3'b110, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OP}};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], {ibex_defines_OPCODE_OP}};
									3'b100, 3'b101, 3'b110, 3'b111: illegal_instr_o = 1'b1;
								endcase
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 5'b00000, 2'b01, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], {ibex_defines_OPCODE_BRANCH}};
					default:
						;
				endcase
			2'b10:
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], {ibex_defines_OPCODE_OPIMM}};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
						if ((instr_i[12] == 1'b1) || (instr_i[6:2] == 5'b00000))
							illegal_instr_o = 1'b1;
					end
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 2'b00, 5'h02, 3'b010, instr_i[11:7], ibex_defines_OPCODE_LOAD};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						if (instr_i[12] == 1'b0) begin
							instr_o = {7'b0000000, instr_i[6:2], 5'b00000, 3'b000, instr_i[11:7], {ibex_defines_OPCODE_OP}};
							if (instr_i[6:2] == 5'b00000)
								instr_o = {12'b000000000000, instr_i[11:7], 3'b000, 5'b00000, {ibex_defines_OPCODE_JALR}};
						end
						else begin
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], {ibex_defines_OPCODE_OP}};
							if (instr_i[11:7] == 5'b00000) begin
								instr_o = 32'h00100073;
								if (instr_i[6:2] != 5'b00000)
									illegal_instr_o = 1'b1;
							end
							else if (instr_i[6:2] == 5'b00000)
								instr_o = {12'b000000000000, instr_i[11:7], 3'b000, 5'b00001, {ibex_defines_OPCODE_JALR}};
						end
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 5'h02, 3'b010, instr_i[11:9], 2'b00, {ibex_defines_OPCODE_STORE}};
					default: illegal_instr_o = 1'b1;
				endcase
			default: instr_o = instr_i;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
endmodule

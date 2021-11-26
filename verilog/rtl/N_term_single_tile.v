// SPDX-FileCopyrightText: 
// 2021 Nguyen Dao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0
module N_term_single (N1END, N2MID, N2END, N4END, NN4END, Ci, S1BEG, S2BEG, S2BEGb, S4BEG, SS4BEG, UserCLK, UserCLKo, FrameStrobe, FrameStrobe_O);
	parameter MaxFramesPerCol = 20;
	parameter FrameBitsPerRow = 32;
	parameter NoConfigBits = 0;
	//  NORTH
	input [3:0] N1END; //wires:4 X_offset:0 Y_offset:1  source_name:NULL destination_name:N1END  
	input [7:0] N2MID; //wires:8 X_offset:0 Y_offset:1  source_name:NULL destination_name:N2MID  
	input [7:0] N2END; //wires:8 X_offset:0 Y_offset:1  source_name:NULL destination_name:N2END  
	input [15:0] N4END; //wires:4 X_offset:0 Y_offset:4  source_name:NULL destination_name:N4END  
	input [15:0] NN4END; //wires:4 X_offset:0 Y_offset:4  source_name:NULL destination_name:NN4END  
	input [0:0] Ci; //wires:1 X_offset:0 Y_offset:1  source_name:NULL destination_name:Ci  
	//  EAST
	//  SOUTH
	output [3:0] S1BEG; //wires:4 X_offset:0 Y_offset:-1  source_name:S1BEG destination_name:NULL  
	output [7:0] S2BEG; //wires:8 X_offset:0 Y_offset:-1  source_name:S2BEG destination_name:NULL  
	output [7:0] S2BEGb; //wires:8 X_offset:0 Y_offset:-1  source_name:S2BEGb destination_name:NULL  
	output [15:0] S4BEG; //wires:4 X_offset:0 Y_offset:-4  source_name:S4BEG destination_name:NULL  
	output [15:0] SS4BEG; //wires:4 X_offset:0 Y_offset:-4  source_name:SS4BEG destination_name:NULL  
	//  WEST
	input UserCLK;
	output UserCLKo;
	input [MaxFramesPerCol-1:0] FrameStrobe; //CONFIG_PORT this is a keyword needed to connect the tile to the bitstream frame register
	output [MaxFramesPerCol-1:0] FrameStrobe_O;
	//global


//signal declarations
//BEL ports (e.g., slices)
//jump wires
//internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
	wire [MaxFramesPerCol-1:0] FrameStrobe_i;
	wire [MaxFramesPerCol-1:0] FrameStrobe_O_i;
	assign FrameStrobe_O_i = FrameStrobe_i;

	my_buf strobe_inbuf_0 (
	.A(FrameStrobe[0]),
	.X(FrameStrobe_i[0])
	)
;
	my_buf strobe_inbuf_1 (
	.A(FrameStrobe[1]),
	.X(FrameStrobe_i[1])
	)
;
	my_buf strobe_inbuf_2 (
	.A(FrameStrobe[2]),
	.X(FrameStrobe_i[2])
	)
;
	my_buf strobe_inbuf_3 (
	.A(FrameStrobe[3]),
	.X(FrameStrobe_i[3])
	)
;
	my_buf strobe_inbuf_4 (
	.A(FrameStrobe[4]),
	.X(FrameStrobe_i[4])
	)
;
	my_buf strobe_inbuf_5 (
	.A(FrameStrobe[5]),
	.X(FrameStrobe_i[5])
	)
;
	my_buf strobe_inbuf_6 (
	.A(FrameStrobe[6]),
	.X(FrameStrobe_i[6])
	)
;
	my_buf strobe_inbuf_7 (
	.A(FrameStrobe[7]),
	.X(FrameStrobe_i[7])
	)
;
	my_buf strobe_inbuf_8 (
	.A(FrameStrobe[8]),
	.X(FrameStrobe_i[8])
	)
;
	my_buf strobe_inbuf_9 (
	.A(FrameStrobe[9]),
	.X(FrameStrobe_i[9])
	)
;
	my_buf strobe_inbuf_10 (
	.A(FrameStrobe[10]),
	.X(FrameStrobe_i[10])
	)
;
	my_buf strobe_inbuf_11 (
	.A(FrameStrobe[11]),
	.X(FrameStrobe_i[11])
	)
;
	my_buf strobe_inbuf_12 (
	.A(FrameStrobe[12]),
	.X(FrameStrobe_i[12])
	)
;
	my_buf strobe_inbuf_13 (
	.A(FrameStrobe[13]),
	.X(FrameStrobe_i[13])
	)
;
	my_buf strobe_inbuf_14 (
	.A(FrameStrobe[14]),
	.X(FrameStrobe_i[14])
	)
;
	my_buf strobe_inbuf_15 (
	.A(FrameStrobe[15]),
	.X(FrameStrobe_i[15])
	)
;
	my_buf strobe_inbuf_16 (
	.A(FrameStrobe[16]),
	.X(FrameStrobe_i[16])
	)
;
	my_buf strobe_inbuf_17 (
	.A(FrameStrobe[17]),
	.X(FrameStrobe_i[17])
	)
;
	my_buf strobe_inbuf_18 (
	.A(FrameStrobe[18]),
	.X(FrameStrobe_i[18])
	)
;
	my_buf strobe_inbuf_19 (
	.A(FrameStrobe[19]),
	.X(FrameStrobe_i[19])
	)
;
	my_buf strobe_outbuf_0 (
	.A(FrameStrobe_O_i[0]),
	.X(FrameStrobe_O[0])
	)
;
	my_buf strobe_outbuf_1 (
	.A(FrameStrobe_O_i[1]),
	.X(FrameStrobe_O[1])
	)
;
	my_buf strobe_outbuf_2 (
	.A(FrameStrobe_O_i[2]),
	.X(FrameStrobe_O[2])
	)
;
	my_buf strobe_outbuf_3 (
	.A(FrameStrobe_O_i[3]),
	.X(FrameStrobe_O[3])
	)
;
	my_buf strobe_outbuf_4 (
	.A(FrameStrobe_O_i[4]),
	.X(FrameStrobe_O[4])
	)
;
	my_buf strobe_outbuf_5 (
	.A(FrameStrobe_O_i[5]),
	.X(FrameStrobe_O[5])
	)
;
	my_buf strobe_outbuf_6 (
	.A(FrameStrobe_O_i[6]),
	.X(FrameStrobe_O[6])
	)
;
	my_buf strobe_outbuf_7 (
	.A(FrameStrobe_O_i[7]),
	.X(FrameStrobe_O[7])
	)
;
	my_buf strobe_outbuf_8 (
	.A(FrameStrobe_O_i[8]),
	.X(FrameStrobe_O[8])
	)
;
	my_buf strobe_outbuf_9 (
	.A(FrameStrobe_O_i[9]),
	.X(FrameStrobe_O[9])
	)
;
	my_buf strobe_outbuf_10 (
	.A(FrameStrobe_O_i[10]),
	.X(FrameStrobe_O[10])
	)
;
	my_buf strobe_outbuf_11 (
	.A(FrameStrobe_O_i[11]),
	.X(FrameStrobe_O[11])
	)
;
	my_buf strobe_outbuf_12 (
	.A(FrameStrobe_O_i[12]),
	.X(FrameStrobe_O[12])
	)
;
	my_buf strobe_outbuf_13 (
	.A(FrameStrobe_O_i[13]),
	.X(FrameStrobe_O[13])
	)
;
	my_buf strobe_outbuf_14 (
	.A(FrameStrobe_O_i[14]),
	.X(FrameStrobe_O[14])
	)
;
	my_buf strobe_outbuf_15 (
	.A(FrameStrobe_O_i[15]),
	.X(FrameStrobe_O[15])
	)
;
	my_buf strobe_outbuf_16 (
	.A(FrameStrobe_O_i[16]),
	.X(FrameStrobe_O[16])
	)
;
	my_buf strobe_outbuf_17 (
	.A(FrameStrobe_O_i[17]),
	.X(FrameStrobe_O[17])
	)
;
	my_buf strobe_outbuf_18 (
	.A(FrameStrobe_O_i[18]),
	.X(FrameStrobe_O[18])
	)
;
	my_buf strobe_outbuf_19 (
	.A(FrameStrobe_O_i[19]),
	.X(FrameStrobe_O[19])
	)
;
	clk_buf inst_clk_buf(.A(UserCLK), .X(UserCLKo));

//BEL component instantiations

//switch matrix component instantiation
	N_term_single_switch_matrix Inst_N_term_single_switch_matrix (
	.N1END0(N1END[0]),
	.N1END1(N1END[1]),
	.N1END2(N1END[2]),
	.N1END3(N1END[3]),
	.N2MID0(N2MID[0]),
	.N2MID1(N2MID[1]),
	.N2MID2(N2MID[2]),
	.N2MID3(N2MID[3]),
	.N2MID4(N2MID[4]),
	.N2MID5(N2MID[5]),
	.N2MID6(N2MID[6]),
	.N2MID7(N2MID[7]),
	.N2END0(N2END[0]),
	.N2END1(N2END[1]),
	.N2END2(N2END[2]),
	.N2END3(N2END[3]),
	.N2END4(N2END[4]),
	.N2END5(N2END[5]),
	.N2END6(N2END[6]),
	.N2END7(N2END[7]),
	.N4END0(N4END[0]),
	.N4END1(N4END[1]),
	.N4END2(N4END[2]),
	.N4END3(N4END[3]),
	.N4END4(N4END[4]),
	.N4END5(N4END[5]),
	.N4END6(N4END[6]),
	.N4END7(N4END[7]),
	.N4END8(N4END[8]),
	.N4END9(N4END[9]),
	.N4END10(N4END[10]),
	.N4END11(N4END[11]),
	.N4END12(N4END[12]),
	.N4END13(N4END[13]),
	.N4END14(N4END[14]),
	.N4END15(N4END[15]),
	.NN4END0(NN4END[0]),
	.NN4END1(NN4END[1]),
	.NN4END2(NN4END[2]),
	.NN4END3(NN4END[3]),
	.NN4END4(NN4END[4]),
	.NN4END5(NN4END[5]),
	.NN4END6(NN4END[6]),
	.NN4END7(NN4END[7]),
	.NN4END8(NN4END[8]),
	.NN4END9(NN4END[9]),
	.NN4END10(NN4END[10]),
	.NN4END11(NN4END[11]),
	.NN4END12(NN4END[12]),
	.NN4END13(NN4END[13]),
	.NN4END14(NN4END[14]),
	.NN4END15(NN4END[15]),
	.Ci0(Ci[0]),
	.S1BEG0(S1BEG[0]),
	.S1BEG1(S1BEG[1]),
	.S1BEG2(S1BEG[2]),
	.S1BEG3(S1BEG[3]),
	.S2BEG0(S2BEG[0]),
	.S2BEG1(S2BEG[1]),
	.S2BEG2(S2BEG[2]),
	.S2BEG3(S2BEG[3]),
	.S2BEG4(S2BEG[4]),
	.S2BEG5(S2BEG[5]),
	.S2BEG6(S2BEG[6]),
	.S2BEG7(S2BEG[7]),
	.S2BEGb0(S2BEGb[0]),
	.S2BEGb1(S2BEGb[1]),
	.S2BEGb2(S2BEGb[2]),
	.S2BEGb3(S2BEGb[3]),
	.S2BEGb4(S2BEGb[4]),
	.S2BEGb5(S2BEGb[5]),
	.S2BEGb6(S2BEGb[6]),
	.S2BEGb7(S2BEGb[7]),
	.S4BEG0(S4BEG[0]),
	.S4BEG1(S4BEG[1]),
	.S4BEG2(S4BEG[2]),
	.S4BEG3(S4BEG[3]),
	.S4BEG4(S4BEG[4]),
	.S4BEG5(S4BEG[5]),
	.S4BEG6(S4BEG[6]),
	.S4BEG7(S4BEG[7]),
	.S4BEG8(S4BEG[8]),
	.S4BEG9(S4BEG[9]),
	.S4BEG10(S4BEG[10]),
	.S4BEG11(S4BEG[11]),
	.S4BEG12(S4BEG[12]),
	.S4BEG13(S4BEG[13]),
	.S4BEG14(S4BEG[14]),
	.S4BEG15(S4BEG[15]),
	.SS4BEG0(SS4BEG[0]),
	.SS4BEG1(SS4BEG[1]),
	.SS4BEG2(SS4BEG[2]),
	.SS4BEG3(SS4BEG[3]),
	.SS4BEG4(SS4BEG[4]),
	.SS4BEG5(SS4BEG[5]),
	.SS4BEG6(SS4BEG[6]),
	.SS4BEG7(SS4BEG[7]),
	.SS4BEG8(SS4BEG[8]),
	.SS4BEG9(SS4BEG[9]),
	.SS4BEG10(SS4BEG[10]),
	.SS4BEG11(SS4BEG[11]),
	.SS4BEG12(SS4BEG[12]),
	.SS4BEG13(SS4BEG[13]),
	.SS4BEG14(SS4BEG[14]),
	.SS4BEG15(SS4BEG[15])
	);

endmodule

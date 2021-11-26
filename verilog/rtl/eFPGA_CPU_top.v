// SPDX-FileCopyrightText: 
// 2021 Nguyen Dao
// 2021 Andrew Attwood
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

module eFPGA_CPU_top (
	// Wishbone Slave ports (WB MI A)
	input wb_clk_i,
	input wb_rst_i,
	input wbs_stb_i,
	input wbs_cyc_i,
	input wbs_we_i,
	input [3:0] wbs_sel_i,
	input [31:0] wbs_dat_i,
	input [31:0] wbs_adr_i,
	output wbs_ack_o,
	output [31:0] wbs_dat_o,

	// Logic Analyzer Signals
	output [2:0] la_data_out,
	input  [3:0] la_data_in,

	// IOs
	input  [37:0] io_in, //CLK: [2:0] eFPGA: [12:3] 
	output [37:0] io_out, //CLK: [2:0] eFPGA: [12:3]
	output [37:0] io_oeb, //CLK: [2:0] eFPGA: [12:3]

	// Independent clock (on independent integer divider)
	input   user_clock2
);

	localparam include_eFPGA = 1;
	localparam NumberOfRows = 14;
	localparam NumberOfCols = 15;
	localparam FrameBitsPerRow = 32;
	localparam MaxFramesPerCol = 20;
	localparam desync_flag = 20;
	localparam FrameSelectWidth = 5;
	localparam RowSelectWidth = 5;

	// External USER ports 
	//inout [16-1:0] PAD; // these are for Dirk and go to the pad ring
	wire [10-1:0] I_top; 
	wire [10-1:0] T_top;
	wire [10-1:0] O_top;
	wire [20-1:0] A_config_C;
	wire [20-1:0] B_config_C;

	wire CLK; // This clock can go to the CPU (connects to the fabric LUT output flops

	// CPU configuration port
	wire SelfWriteStrobe; // must decode address and write enable
	wire [32-1:0] SelfWriteData; // configuration data write port

	// UART configuration port
	wire Rx;
	wire ComActive;
	wire ReceiveLED;

	// BitBang configuration port
	wire s_clk;
	wire s_data;

	//BlockRAM ports
	wire [80-1:0] RAM2FAB_D;
	wire [80-1:0] FAB2RAM_D;
	wire [40-1:0] FAB2RAM_A;
	wire [20-1:0] FAB2RAM_C;
	wire [20-1:0] Config_accessC;

	// Signal declarations
	wire [(NumberOfRows*FrameBitsPerRow)-1:0] FrameRegister;

	wire [(MaxFramesPerCol*NumberOfCols)-1:0] FrameSelect;

	wire [(FrameBitsPerRow*(NumberOfRows+2))-1:0] FrameData;

	wire [FrameBitsPerRow-1:0] FrameAddressRegister;
	wire LongFrameStrobe;
	wire [31:0] LocalWriteData;
	wire LocalWriteStrobe;
	wire [RowSelectWidth-1:0] RowSelect;

	wire external_clock;
	wire [1:0] clk_sel;

	assign external_clock = io_in[0];
	assign clk_sel = {io_in[2],io_in[1]};
	assign s_clk          = io_in[3];
	assign s_data         = io_in[4];
	assign Rx             = io_in[5];
	assign io_out[6]     = ReceiveLED;

	assign io_oeb[6:0] = 7'b0111111; //CLK and eFPGA configuration
	assign io_oeb[16:7] = 10'b0010111111; //CPU

	assign CLK = clk_sel[0] ? (clk_sel[1] ? user_clock2 : wb_clk_i) : external_clock;

	assign la_data_out[2:0] = {ReceiveLED, Rx, ComActive};

	assign O_top = io_in[26:17]; 
	assign io_out[26:17] = I_top; 
	assign io_oeb[26:17] = T_top; //eFPGA IO pins

	// To CPU
	wire [36-1:0] W_OPA; //from RISCV
	wire [36-1:0] W_OPB; //from RISCV
	wire [36-1:0] W_RES0; //to RISCV
	wire [36-1:0] W_RES1; //to RISCV
	wire [36-1:0] W_RES2; //to RISCV

	wire [36-1:0] E_OPA; //from RISCV
	wire [36-1:0] E_OPB; //from RISCV
	wire [36-1:0] E_RES0; //to RISCV
	wire [36-1:0] E_RES1; //to RISCV
	wire [36-1:0] E_RES2; //to RISCV

	wire [31:0] eFPGA_operand_a_1_o;
	assign W_OPA[34:3] = eFPGA_operand_a_1_o;
	assign SelfWriteData = eFPGA_operand_a_1_o;


reg debug_req_1;
reg fetch_enable_1;
reg debug_req_2;
reg fetch_enable_2;

always @(*) begin
	if(io_in[7] == 1'b0 )begin
		debug_req_1 =  la_data_in[0];
		fetch_enable_1 = la_data_in[1];
		debug_req_2 = la_data_in[2];
		fetch_enable_2 = la_data_in[3];
	end 
	else begin
		debug_req_1 = io_in[8];
		fetch_enable_1 = io_in[9];
		debug_req_2 = io_in[10];
		fetch_enable_2 = io_in[11];
	end
end 



//CPU instantiation
 	forte_soc_top   forte_soc_top_i (
 
   	//core 1
    .debug_req_1_i(debug_req_1), //todo needs LA in PIN
    .fetch_enable_1_i(fetch_enable_1), //todo needs LA in PIN
    .irq_ack_1_o(W_OPA[0]),
    .irq_1_i(W_RES1[33]),
    .irq_id_1_i({W_RES1[32],W_RES0[35:32]}),
    .irq_id_1_o(W_OPA[2:1]),
    .eFPGA_operand_a_1_o(eFPGA_operand_a_1_o),
    .eFPGA_operand_b_1_o(W_OPB[31:0]),
    .eFPGA_result_a_1_i(W_RES0[31:0]),
    .eFPGA_result_b_1_i(W_RES1[31:0]),
    .eFPGA_result_c_1_i(W_RES2[31:0]),
    .eFPGA_write_strobe_1_o(SelfWriteStrobe),//todo write strobe connection
    .eFPGA_fpga_done_1_i(W_RES1[34]), 
    .eFPGA_delay_1_o(W_OPB[33:32]),
    .eFPGA_en_1_o(W_OPA[35]),
    .eFPGA_operator_1_o(W_OPB[35:34]),

	//Wishbone to carvel
    .wb_clk_i(CLK), 
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

	//core 2
    .debug_req_2_i(debug_req_2), //todo needs LA in PIN
    .fetch_enable_2_i(fetch_enable_2), //todo needs LA in PIN
    .irq_ack_2_o(E_OPA[0]), 
    .irq_2_i(E_RES1[33]),
    .irq_id_2_i({E_RES1[32],E_RES0[35:32]}),
    .irq_id_2_o(E_OPA[2:1]),
    .eFPGA_operand_a_2_o(E_OPA[34:3]),
    .eFPGA_operand_b_2_o(E_OPB[31:0]),
    .eFPGA_result_a_2_i(E_RES0[31:0]),
    .eFPGA_result_b_2_i(E_RES1[31:0]),
    .eFPGA_result_c_2_i(E_RES2[31:0]),
    .eFPGA_write_strobe_2_o(io_out[16]),
    .eFPGA_fpga_done_2_i(E_RES1[34]),
    .eFPGA_delay_2_o(E_OPB[33:32]),
    .eFPGA_en_2_o(E_OPA[35]),
    .eFPGA_operator_2_o(E_OPB[35:34]),

	//uart pins to USER area off chip IO
    .rxd_uart(io_in[12]), 
    .txd_uart(io_out[13]), 
    .rxd_uart_to_mem(io_in[14]), 
    .txd_uart_to_mem(io_out[15]), 
    .error_uart_to_mem(io_out[16]) 
);

Config Config_inst (
	.CLK(CLK),
	.Rx(Rx),
	.ComActive(ComActive),
	.ReceiveLED(ReceiveLED),
	.s_clk(s_clk),
	.s_data(s_data),
	.SelfWriteData(SelfWriteData),
	.SelfWriteStrobe(SelfWriteStrobe),
	
	.ConfigWriteData(LocalWriteData),
	.ConfigWriteStrobe(LocalWriteStrobe),
	
	.FrameAddressRegister(FrameAddressRegister),
	.LongFrameStrobe(LongFrameStrobe),
	.RowSelect(RowSelect)
);


	// L: if include_eFPGA = 1 generate

	Frame_Data_Reg_0 Inst_Frame_Data_Reg_0 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[0*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_1 Inst_Frame_Data_Reg_1 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[1*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_2 Inst_Frame_Data_Reg_2 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[2*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_3 Inst_Frame_Data_Reg_3 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[3*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_4 Inst_Frame_Data_Reg_4 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[4*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_5 Inst_Frame_Data_Reg_5 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[5*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_6 Inst_Frame_Data_Reg_6 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[6*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_7 Inst_Frame_Data_Reg_7 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[7*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_8 Inst_Frame_Data_Reg_8 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[8*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_9 Inst_Frame_Data_Reg_9 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[9*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_10 Inst_Frame_Data_Reg_10 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[10*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_11 Inst_Frame_Data_Reg_11 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[11*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_12 Inst_Frame_Data_Reg_12 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[12*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Data_Reg_13 Inst_Frame_Data_Reg_13 (
	.FrameData_I(LocalWriteData),
	.FrameData_O(FrameRegister[13*FrameBitsPerRow+:FrameBitsPerRow]),
	.RowSelect(RowSelect),
	.CLK(CLK)
	);

	Frame_Select_0 Inst_Frame_Select_0 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[0*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_1 Inst_Frame_Select_1 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[1*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_2 Inst_Frame_Select_2 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[2*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_3 Inst_Frame_Select_3 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[3*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_4 Inst_Frame_Select_4 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[4*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_5 Inst_Frame_Select_5 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[5*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_6 Inst_Frame_Select_6 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[6*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_7 Inst_Frame_Select_7 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[7*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_8 Inst_Frame_Select_8 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[8*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_9 Inst_Frame_Select_9 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[9*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_10 Inst_Frame_Select_10 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[10*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_11 Inst_Frame_Select_11 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[11*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_12 Inst_Frame_Select_12 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[12*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_13 Inst_Frame_Select_13 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[13*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	Frame_Select_14 Inst_Frame_Select_14 (
	.FrameStrobe_I(FrameAddressRegister[MaxFramesPerCol-1:0]),
	.FrameStrobe_O(FrameSelect[14*MaxFramesPerCol +: MaxFramesPerCol]),
	.FrameSelect(FrameAddressRegister[FrameBitsPerRow-1:FrameBitsPerRow-(FrameSelectWidth)]),
	.FrameStrobe(LongFrameStrobe)
	);

	eFPGA Inst_eFPGA(
	.Tile_X0Y10_A_I_top(I_top[9]),
	.Tile_X0Y10_B_I_top(I_top[8]),
	.Tile_X0Y11_A_I_top(I_top[7]),
	.Tile_X0Y11_B_I_top(I_top[6]),
	.Tile_X0Y12_A_I_top(I_top[5]),
	.Tile_X0Y12_B_I_top(I_top[4]),
	.Tile_X0Y13_A_I_top(I_top[3]),
	.Tile_X0Y13_B_I_top(I_top[2]),
	.Tile_X0Y14_A_I_top(I_top[1]),
	.Tile_X0Y14_B_I_top(I_top[0]),

	.Tile_X0Y10_A_T_top(T_top[9]),
	.Tile_X0Y10_B_T_top(T_top[8]),
	.Tile_X0Y11_A_T_top(T_top[7]),
	.Tile_X0Y11_B_T_top(T_top[6]),
	.Tile_X0Y12_A_T_top(T_top[5]),
	.Tile_X0Y12_B_T_top(T_top[4]),
	.Tile_X0Y13_A_T_top(T_top[3]),
	.Tile_X0Y13_B_T_top(T_top[2]),
	.Tile_X0Y14_A_T_top(T_top[1]),
	.Tile_X0Y14_B_T_top(T_top[0]),

	.Tile_X0Y10_A_O_top(O_top[9]),
	.Tile_X0Y10_B_O_top(O_top[8]),
	.Tile_X0Y11_A_O_top(O_top[7]),
	.Tile_X0Y11_B_O_top(O_top[6]),
	.Tile_X0Y12_A_O_top(O_top[5]),
	.Tile_X0Y12_B_O_top(O_top[4]),
	.Tile_X0Y13_A_O_top(O_top[3]),
	.Tile_X0Y13_B_O_top(O_top[2]),
	.Tile_X0Y14_A_O_top(O_top[1]),
	.Tile_X0Y14_B_O_top(O_top[0]),

	.Tile_X0Y10_A_config_C_bit0(A_config_C[19]),
	.Tile_X0Y10_A_config_C_bit1(A_config_C[18]),
	.Tile_X0Y10_A_config_C_bit2(A_config_C[17]),
	.Tile_X0Y10_A_config_C_bit3(A_config_C[16]),
	.Tile_X0Y11_A_config_C_bit0(A_config_C[15]),
	.Tile_X0Y11_A_config_C_bit1(A_config_C[14]),
	.Tile_X0Y11_A_config_C_bit2(A_config_C[13]),
	.Tile_X0Y11_A_config_C_bit3(A_config_C[12]),
	.Tile_X0Y12_A_config_C_bit0(A_config_C[11]),
	.Tile_X0Y12_A_config_C_bit1(A_config_C[10]),
	.Tile_X0Y12_A_config_C_bit2(A_config_C[9]),
	.Tile_X0Y12_A_config_C_bit3(A_config_C[8]),
	.Tile_X0Y13_A_config_C_bit0(A_config_C[7]),
	.Tile_X0Y13_A_config_C_bit1(A_config_C[6]),
	.Tile_X0Y13_A_config_C_bit2(A_config_C[5]),
	.Tile_X0Y13_A_config_C_bit3(A_config_C[4]),
	.Tile_X0Y14_A_config_C_bit0(A_config_C[3]),
	.Tile_X0Y14_A_config_C_bit1(A_config_C[2]),
	.Tile_X0Y14_A_config_C_bit2(A_config_C[1]),
	.Tile_X0Y14_A_config_C_bit3(A_config_C[0]),

	.Tile_X0Y10_B_config_C_bit0(B_config_C[19]),
	.Tile_X0Y10_B_config_C_bit1(B_config_C[18]),
	.Tile_X0Y10_B_config_C_bit2(B_config_C[17]),
	.Tile_X0Y10_B_config_C_bit3(B_config_C[16]),
	.Tile_X0Y11_B_config_C_bit0(B_config_C[15]),
	.Tile_X0Y11_B_config_C_bit1(B_config_C[14]),
	.Tile_X0Y11_B_config_C_bit2(B_config_C[13]),
	.Tile_X0Y11_B_config_C_bit3(B_config_C[12]),
	.Tile_X0Y12_B_config_C_bit0(B_config_C[11]),
	.Tile_X0Y12_B_config_C_bit1(B_config_C[10]),
	.Tile_X0Y12_B_config_C_bit2(B_config_C[9]),
	.Tile_X0Y12_B_config_C_bit3(B_config_C[8]),
	.Tile_X0Y13_B_config_C_bit0(B_config_C[7]),
	.Tile_X0Y13_B_config_C_bit1(B_config_C[6]),
	.Tile_X0Y13_B_config_C_bit2(B_config_C[5]),
	.Tile_X0Y13_B_config_C_bit3(B_config_C[4]),
	.Tile_X0Y14_B_config_C_bit0(B_config_C[3]),
	.Tile_X0Y14_B_config_C_bit1(B_config_C[2]),
	.Tile_X0Y14_B_config_C_bit2(B_config_C[1]),
	.Tile_X0Y14_B_config_C_bit3(B_config_C[0]),

	.Tile_X3Y1_OPA_I0(W_OPA[35]),
	.Tile_X3Y1_OPA_I1(W_OPA[34]),
	.Tile_X3Y1_OPA_I2(W_OPA[33]),
	.Tile_X3Y1_OPA_I3(W_OPA[32]),
	.Tile_X3Y2_OPA_I0(W_OPA[31]),
	.Tile_X3Y2_OPA_I1(W_OPA[30]),
	.Tile_X3Y2_OPA_I2(W_OPA[29]),
	.Tile_X3Y2_OPA_I3(W_OPA[28]),
	.Tile_X3Y3_OPA_I0(W_OPA[27]),
	.Tile_X3Y3_OPA_I1(W_OPA[26]),
	.Tile_X3Y3_OPA_I2(W_OPA[25]),
	.Tile_X3Y3_OPA_I3(W_OPA[24]),
	.Tile_X3Y4_OPA_I0(W_OPA[23]),
	.Tile_X3Y4_OPA_I1(W_OPA[22]),
	.Tile_X3Y4_OPA_I2(W_OPA[21]),
	.Tile_X3Y4_OPA_I3(W_OPA[20]),
	.Tile_X3Y5_OPA_I0(W_OPA[19]),
	.Tile_X3Y5_OPA_I1(W_OPA[18]),
	.Tile_X3Y5_OPA_I2(W_OPA[17]),
	.Tile_X3Y5_OPA_I3(W_OPA[16]),
	.Tile_X3Y6_OPA_I0(W_OPA[15]),
	.Tile_X3Y6_OPA_I1(W_OPA[14]),
	.Tile_X3Y6_OPA_I2(W_OPA[13]),
	.Tile_X3Y6_OPA_I3(W_OPA[12]),
	.Tile_X3Y7_OPA_I0(W_OPA[11]),
	.Tile_X3Y7_OPA_I1(W_OPA[10]),
	.Tile_X3Y7_OPA_I2(W_OPA[9]),
	.Tile_X3Y7_OPA_I3(W_OPA[8]),
	.Tile_X3Y8_OPA_I0(W_OPA[7]),
	.Tile_X3Y8_OPA_I1(W_OPA[6]),
	.Tile_X3Y8_OPA_I2(W_OPA[5]),
	.Tile_X3Y8_OPA_I3(W_OPA[4]),
	.Tile_X3Y9_OPA_I0(W_OPA[3]),
	.Tile_X3Y9_OPA_I1(W_OPA[2]),
	.Tile_X3Y9_OPA_I2(W_OPA[1]),
	.Tile_X3Y9_OPA_I3(W_OPA[0]),

	.Tile_X3Y1_OPB_I0(W_OPB[35]),
	.Tile_X3Y1_OPB_I1(W_OPB[34]),
	.Tile_X3Y1_OPB_I2(W_OPB[33]),
	.Tile_X3Y1_OPB_I3(W_OPB[32]),
	.Tile_X3Y2_OPB_I0(W_OPB[31]),
	.Tile_X3Y2_OPB_I1(W_OPB[30]),
	.Tile_X3Y2_OPB_I2(W_OPB[29]),
	.Tile_X3Y2_OPB_I3(W_OPB[28]),
	.Tile_X3Y3_OPB_I0(W_OPB[27]),
	.Tile_X3Y3_OPB_I1(W_OPB[26]),
	.Tile_X3Y3_OPB_I2(W_OPB[25]),
	.Tile_X3Y3_OPB_I3(W_OPB[24]),
	.Tile_X3Y4_OPB_I0(W_OPB[23]),
	.Tile_X3Y4_OPB_I1(W_OPB[22]),
	.Tile_X3Y4_OPB_I2(W_OPB[21]),
	.Tile_X3Y4_OPB_I3(W_OPB[20]),
	.Tile_X3Y5_OPB_I0(W_OPB[19]),
	.Tile_X3Y5_OPB_I1(W_OPB[18]),
	.Tile_X3Y5_OPB_I2(W_OPB[17]),
	.Tile_X3Y5_OPB_I3(W_OPB[16]),
	.Tile_X3Y6_OPB_I0(W_OPB[15]),
	.Tile_X3Y6_OPB_I1(W_OPB[14]),
	.Tile_X3Y6_OPB_I2(W_OPB[13]),
	.Tile_X3Y6_OPB_I3(W_OPB[12]),
	.Tile_X3Y7_OPB_I0(W_OPB[11]),
	.Tile_X3Y7_OPB_I1(W_OPB[10]),
	.Tile_X3Y7_OPB_I2(W_OPB[9]),
	.Tile_X3Y7_OPB_I3(W_OPB[8]),
	.Tile_X3Y8_OPB_I0(W_OPB[7]),
	.Tile_X3Y8_OPB_I1(W_OPB[6]),
	.Tile_X3Y8_OPB_I2(W_OPB[5]),
	.Tile_X3Y8_OPB_I3(W_OPB[4]),
	.Tile_X3Y9_OPB_I0(W_OPB[3]),
	.Tile_X3Y9_OPB_I1(W_OPB[2]),
	.Tile_X3Y9_OPB_I2(W_OPB[1]),
	.Tile_X3Y9_OPB_I3(W_OPB[0]),

	.Tile_X3Y1_RES0_O0(W_RES0[35]),
	.Tile_X3Y1_RES0_O1(W_RES0[34]),
	.Tile_X3Y1_RES0_O2(W_RES0[33]),
	.Tile_X3Y1_RES0_O3(W_RES0[32]),
	.Tile_X3Y2_RES0_O0(W_RES0[31]),
	.Tile_X3Y2_RES0_O1(W_RES0[30]),
	.Tile_X3Y2_RES0_O2(W_RES0[29]),
	.Tile_X3Y2_RES0_O3(W_RES0[28]),
	.Tile_X3Y3_RES0_O0(W_RES0[27]),
	.Tile_X3Y3_RES0_O1(W_RES0[26]),
	.Tile_X3Y3_RES0_O2(W_RES0[25]),
	.Tile_X3Y3_RES0_O3(W_RES0[24]),
	.Tile_X3Y4_RES0_O0(W_RES0[23]),
	.Tile_X3Y4_RES0_O1(W_RES0[22]),
	.Tile_X3Y4_RES0_O2(W_RES0[21]),
	.Tile_X3Y4_RES0_O3(W_RES0[20]),
	.Tile_X3Y5_RES0_O0(W_RES0[19]),
	.Tile_X3Y5_RES0_O1(W_RES0[18]),
	.Tile_X3Y5_RES0_O2(W_RES0[17]),
	.Tile_X3Y5_RES0_O3(W_RES0[16]),
	.Tile_X3Y6_RES0_O0(W_RES0[15]),
	.Tile_X3Y6_RES0_O1(W_RES0[14]),
	.Tile_X3Y6_RES0_O2(W_RES0[13]),
	.Tile_X3Y6_RES0_O3(W_RES0[12]),
	.Tile_X3Y7_RES0_O0(W_RES0[11]),
	.Tile_X3Y7_RES0_O1(W_RES0[10]),
	.Tile_X3Y7_RES0_O2(W_RES0[9]),
	.Tile_X3Y7_RES0_O3(W_RES0[8]),
	.Tile_X3Y8_RES0_O0(W_RES0[7]),
	.Tile_X3Y8_RES0_O1(W_RES0[6]),
	.Tile_X3Y8_RES0_O2(W_RES0[5]),
	.Tile_X3Y8_RES0_O3(W_RES0[4]),
	.Tile_X3Y9_RES0_O0(W_RES0[3]),
	.Tile_X3Y9_RES0_O1(W_RES0[2]),
	.Tile_X3Y9_RES0_O2(W_RES0[1]),
	.Tile_X3Y9_RES0_O3(W_RES0[0]),
	
	.Tile_X3Y1_RES1_O0(W_RES1[35]),
	.Tile_X3Y1_RES1_O1(W_RES1[34]),
	.Tile_X3Y1_RES1_O2(W_RES1[33]),
	.Tile_X3Y1_RES1_O3(W_RES1[32]),
	.Tile_X3Y2_RES1_O0(W_RES1[31]),
	.Tile_X3Y2_RES1_O1(W_RES1[30]),
	.Tile_X3Y2_RES1_O2(W_RES1[29]),
	.Tile_X3Y2_RES1_O3(W_RES1[28]),
	.Tile_X3Y3_RES1_O0(W_RES1[27]),
	.Tile_X3Y3_RES1_O1(W_RES1[26]),
	.Tile_X3Y3_RES1_O2(W_RES1[25]),
	.Tile_X3Y3_RES1_O3(W_RES1[24]),
	.Tile_X3Y4_RES1_O0(W_RES1[23]),
	.Tile_X3Y4_RES1_O1(W_RES1[22]),
	.Tile_X3Y4_RES1_O2(W_RES1[21]),
	.Tile_X3Y4_RES1_O3(W_RES1[20]),
	.Tile_X3Y5_RES1_O0(W_RES1[19]),
	.Tile_X3Y5_RES1_O1(W_RES1[18]),
	.Tile_X3Y5_RES1_O2(W_RES1[17]),
	.Tile_X3Y5_RES1_O3(W_RES1[16]),
	.Tile_X3Y6_RES1_O0(W_RES1[15]),
	.Tile_X3Y6_RES1_O1(W_RES1[14]),
	.Tile_X3Y6_RES1_O2(W_RES1[13]),
	.Tile_X3Y6_RES1_O3(W_RES1[12]),
	.Tile_X3Y7_RES1_O0(W_RES1[11]),
	.Tile_X3Y7_RES1_O1(W_RES1[10]),
	.Tile_X3Y7_RES1_O2(W_RES1[9]),
	.Tile_X3Y7_RES1_O3(W_RES1[8]),
	.Tile_X3Y8_RES1_O0(W_RES1[7]),
	.Tile_X3Y8_RES1_O1(W_RES1[6]),
	.Tile_X3Y8_RES1_O2(W_RES1[5]),
	.Tile_X3Y8_RES1_O3(W_RES1[4]),
	.Tile_X3Y9_RES1_O0(W_RES1[3]),
	.Tile_X3Y9_RES1_O1(W_RES1[2]),
	.Tile_X3Y9_RES1_O2(W_RES1[1]),
	.Tile_X3Y9_RES1_O3(W_RES1[0]),
	
	.Tile_X3Y1_RES2_O0(W_RES2[35]),
	.Tile_X3Y1_RES2_O1(W_RES2[34]),
	.Tile_X3Y1_RES2_O2(W_RES2[33]),
	.Tile_X3Y1_RES2_O3(W_RES2[32]),
	.Tile_X3Y2_RES2_O0(W_RES2[31]),
	.Tile_X3Y2_RES2_O1(W_RES2[30]),
	.Tile_X3Y2_RES2_O2(W_RES2[29]),
	.Tile_X3Y2_RES2_O3(W_RES2[28]),
	.Tile_X3Y3_RES2_O0(W_RES2[27]),
	.Tile_X3Y3_RES2_O1(W_RES2[26]),
	.Tile_X3Y3_RES2_O2(W_RES2[25]),
	.Tile_X3Y3_RES2_O3(W_RES2[24]),
	.Tile_X3Y4_RES2_O0(W_RES2[23]),
	.Tile_X3Y4_RES2_O1(W_RES2[22]),
	.Tile_X3Y4_RES2_O2(W_RES2[21]),
	.Tile_X3Y4_RES2_O3(W_RES2[20]),
	.Tile_X3Y5_RES2_O0(W_RES2[19]),
	.Tile_X3Y5_RES2_O1(W_RES2[18]),
	.Tile_X3Y5_RES2_O2(W_RES2[17]),
	.Tile_X3Y5_RES2_O3(W_RES2[16]),
	.Tile_X3Y6_RES2_O0(W_RES2[15]),
	.Tile_X3Y6_RES2_O1(W_RES2[14]),
	.Tile_X3Y6_RES2_O2(W_RES2[13]),
	.Tile_X3Y6_RES2_O3(W_RES2[12]),
	.Tile_X3Y7_RES2_O0(W_RES2[11]),
	.Tile_X3Y7_RES2_O1(W_RES2[10]),
	.Tile_X3Y7_RES2_O2(W_RES2[9]),
	.Tile_X3Y7_RES2_O3(W_RES2[8]),
	.Tile_X3Y8_RES2_O0(W_RES2[7]),
	.Tile_X3Y8_RES2_O1(W_RES2[6]),
	.Tile_X3Y8_RES2_O2(W_RES2[5]),
	.Tile_X3Y8_RES2_O3(W_RES2[4]),
	.Tile_X3Y9_RES2_O0(W_RES2[3]),
	.Tile_X3Y9_RES2_O1(W_RES2[2]),
	.Tile_X3Y9_RES2_O2(W_RES2[1]),
	.Tile_X3Y9_RES2_O3(W_RES2[0]),

	.Tile_X11Y1_OPA_I0(E_OPA[35]),
	.Tile_X11Y1_OPA_I1(E_OPA[34]),
	.Tile_X11Y1_OPA_I2(E_OPA[33]),
	.Tile_X11Y1_OPA_I3(E_OPA[32]),
	.Tile_X11Y2_OPA_I0(E_OPA[31]),
	.Tile_X11Y2_OPA_I1(E_OPA[30]),
	.Tile_X11Y2_OPA_I2(E_OPA[29]),
	.Tile_X11Y2_OPA_I3(E_OPA[28]),
	.Tile_X11Y3_OPA_I0(E_OPA[27]),
	.Tile_X11Y3_OPA_I1(E_OPA[26]),
	.Tile_X11Y3_OPA_I2(E_OPA[25]),
	.Tile_X11Y3_OPA_I3(E_OPA[24]),
	.Tile_X11Y4_OPA_I0(E_OPA[23]),
	.Tile_X11Y4_OPA_I1(E_OPA[22]),
	.Tile_X11Y4_OPA_I2(E_OPA[21]),
	.Tile_X11Y4_OPA_I3(E_OPA[20]),
	.Tile_X11Y5_OPA_I0(E_OPA[19]),
	.Tile_X11Y5_OPA_I1(E_OPA[18]),
	.Tile_X11Y5_OPA_I2(E_OPA[17]),
	.Tile_X11Y5_OPA_I3(E_OPA[16]),
	.Tile_X11Y6_OPA_I0(E_OPA[15]),
	.Tile_X11Y6_OPA_I1(E_OPA[14]),
	.Tile_X11Y6_OPA_I2(E_OPA[13]),
	.Tile_X11Y6_OPA_I3(E_OPA[12]),
	.Tile_X11Y7_OPA_I0(E_OPA[11]),
	.Tile_X11Y7_OPA_I1(E_OPA[10]),
	.Tile_X11Y7_OPA_I2(E_OPA[9]),
	.Tile_X11Y7_OPA_I3(E_OPA[8]),
	.Tile_X11Y8_OPA_I0(E_OPA[7]),
	.Tile_X11Y8_OPA_I1(E_OPA[6]),
	.Tile_X11Y8_OPA_I2(E_OPA[5]),
	.Tile_X11Y8_OPA_I3(E_OPA[4]),
	.Tile_X11Y9_OPA_I0(E_OPA[3]),
	.Tile_X11Y9_OPA_I1(E_OPA[2]),
	.Tile_X11Y9_OPA_I2(E_OPA[1]),
	.Tile_X11Y9_OPA_I3(E_OPA[0]),
	
	.Tile_X11Y1_OPB_I0(E_OPB[35]),
	.Tile_X11Y1_OPB_I1(E_OPB[34]),
	.Tile_X11Y1_OPB_I2(E_OPB[33]),
	.Tile_X11Y1_OPB_I3(E_OPB[32]),
	.Tile_X11Y2_OPB_I0(E_OPB[31]),
	.Tile_X11Y2_OPB_I1(E_OPB[30]),
	.Tile_X11Y2_OPB_I2(E_OPB[29]),
	.Tile_X11Y2_OPB_I3(E_OPB[28]),
	.Tile_X11Y3_OPB_I0(E_OPB[27]),
	.Tile_X11Y3_OPB_I1(E_OPB[26]),
	.Tile_X11Y3_OPB_I2(E_OPB[25]),
	.Tile_X11Y3_OPB_I3(E_OPB[24]),
	.Tile_X11Y4_OPB_I0(E_OPB[23]),
	.Tile_X11Y4_OPB_I1(E_OPB[22]),
	.Tile_X11Y4_OPB_I2(E_OPB[21]),
	.Tile_X11Y4_OPB_I3(E_OPB[20]),
	.Tile_X11Y5_OPB_I0(E_OPB[19]),
	.Tile_X11Y5_OPB_I1(E_OPB[18]),
	.Tile_X11Y5_OPB_I2(E_OPB[17]),
	.Tile_X11Y5_OPB_I3(E_OPB[16]),
	.Tile_X11Y6_OPB_I0(E_OPB[15]),
	.Tile_X11Y6_OPB_I1(E_OPB[14]),
	.Tile_X11Y6_OPB_I2(E_OPB[13]),
	.Tile_X11Y6_OPB_I3(E_OPB[12]),
	.Tile_X11Y7_OPB_I0(E_OPB[11]),
	.Tile_X11Y7_OPB_I1(E_OPB[10]),
	.Tile_X11Y7_OPB_I2(E_OPB[9]),
	.Tile_X11Y7_OPB_I3(E_OPB[8]),
	.Tile_X11Y8_OPB_I0(E_OPB[7]),
	.Tile_X11Y8_OPB_I1(E_OPB[6]),
	.Tile_X11Y8_OPB_I2(E_OPB[5]),
	.Tile_X11Y8_OPB_I3(E_OPB[4]),
	.Tile_X11Y9_OPB_I0(E_OPB[3]),
	.Tile_X11Y9_OPB_I1(E_OPB[2]),
	.Tile_X11Y9_OPB_I2(E_OPB[1]),
	.Tile_X11Y9_OPB_I3(E_OPB[0]),
	
	.Tile_X11Y1_RES0_O0(E_RES0[35]),
	.Tile_X11Y1_RES0_O1(E_RES0[34]),
	.Tile_X11Y1_RES0_O2(E_RES0[33]),
	.Tile_X11Y1_RES0_O3(E_RES0[32]),
	.Tile_X11Y2_RES0_O0(E_RES0[31]),
	.Tile_X11Y2_RES0_O1(E_RES0[30]),
	.Tile_X11Y2_RES0_O2(E_RES0[29]),
	.Tile_X11Y2_RES0_O3(E_RES0[28]),
	.Tile_X11Y3_RES0_O0(E_RES0[27]),
	.Tile_X11Y3_RES0_O1(E_RES0[26]),
	.Tile_X11Y3_RES0_O2(E_RES0[25]),
	.Tile_X11Y3_RES0_O3(E_RES0[24]),
	.Tile_X11Y4_RES0_O0(E_RES0[23]),
	.Tile_X11Y4_RES0_O1(E_RES0[22]),
	.Tile_X11Y4_RES0_O2(E_RES0[21]),
	.Tile_X11Y4_RES0_O3(E_RES0[20]),
	.Tile_X11Y5_RES0_O0(E_RES0[19]),
	.Tile_X11Y5_RES0_O1(E_RES0[18]),
	.Tile_X11Y5_RES0_O2(E_RES0[17]),
	.Tile_X11Y5_RES0_O3(E_RES0[16]),
	.Tile_X11Y6_RES0_O0(E_RES0[15]),
	.Tile_X11Y6_RES0_O1(E_RES0[14]),
	.Tile_X11Y6_RES0_O2(E_RES0[13]),
	.Tile_X11Y6_RES0_O3(E_RES0[12]),
	.Tile_X11Y7_RES0_O0(E_RES0[11]),
	.Tile_X11Y7_RES0_O1(E_RES0[10]),
	.Tile_X11Y7_RES0_O2(E_RES0[9]),
	.Tile_X11Y7_RES0_O3(E_RES0[8]),
	.Tile_X11Y8_RES0_O0(E_RES0[7]),
	.Tile_X11Y8_RES0_O1(E_RES0[6]),
	.Tile_X11Y8_RES0_O2(E_RES0[5]),
	.Tile_X11Y8_RES0_O3(E_RES0[4]),
	.Tile_X11Y9_RES0_O0(E_RES0[3]),
	.Tile_X11Y9_RES0_O1(E_RES0[2]),
	.Tile_X11Y9_RES0_O2(E_RES0[1]),
	.Tile_X11Y9_RES0_O3(E_RES0[0]),
	
	.Tile_X11Y1_RES1_O0(E_RES1[35]),
	.Tile_X11Y1_RES1_O1(E_RES1[34]),
	.Tile_X11Y1_RES1_O2(E_RES1[33]),
	.Tile_X11Y1_RES1_O3(E_RES1[32]),
	.Tile_X11Y2_RES1_O0(E_RES1[31]),
	.Tile_X11Y2_RES1_O1(E_RES1[30]),
	.Tile_X11Y2_RES1_O2(E_RES1[29]),
	.Tile_X11Y2_RES1_O3(E_RES1[28]),
	.Tile_X11Y3_RES1_O0(E_RES1[27]),
	.Tile_X11Y3_RES1_O1(E_RES1[26]),
	.Tile_X11Y3_RES1_O2(E_RES1[25]),
	.Tile_X11Y3_RES1_O3(E_RES1[24]),
	.Tile_X11Y4_RES1_O0(E_RES1[23]),
	.Tile_X11Y4_RES1_O1(E_RES1[22]),
	.Tile_X11Y4_RES1_O2(E_RES1[21]),
	.Tile_X11Y4_RES1_O3(E_RES1[20]),
	.Tile_X11Y5_RES1_O0(E_RES1[19]),
	.Tile_X11Y5_RES1_O1(E_RES1[18]),
	.Tile_X11Y5_RES1_O2(E_RES1[17]),
	.Tile_X11Y5_RES1_O3(E_RES1[16]),
	.Tile_X11Y6_RES1_O0(E_RES1[15]),
	.Tile_X11Y6_RES1_O1(E_RES1[14]),
	.Tile_X11Y6_RES1_O2(E_RES1[13]),
	.Tile_X11Y6_RES1_O3(E_RES1[12]),
	.Tile_X11Y7_RES1_O0(E_RES1[11]),
	.Tile_X11Y7_RES1_O1(E_RES1[10]),
	.Tile_X11Y7_RES1_O2(E_RES1[9]),
	.Tile_X11Y7_RES1_O3(E_RES1[8]),
	.Tile_X11Y8_RES1_O0(E_RES1[7]),
	.Tile_X11Y8_RES1_O1(E_RES1[6]),
	.Tile_X11Y8_RES1_O2(E_RES1[5]),
	.Tile_X11Y8_RES1_O3(E_RES1[4]),
	.Tile_X11Y9_RES1_O0(E_RES1[3]),
	.Tile_X11Y9_RES1_O1(E_RES1[2]),
	.Tile_X11Y9_RES1_O2(E_RES1[1]),
	.Tile_X11Y9_RES1_O3(E_RES1[0]),
	
	.Tile_X11Y1_RES2_O0(E_RES2[35]),
	.Tile_X11Y1_RES2_O1(E_RES2[34]),
	.Tile_X11Y1_RES2_O2(E_RES2[33]),
	.Tile_X11Y1_RES2_O3(E_RES2[32]),
	.Tile_X11Y2_RES2_O0(E_RES2[31]),
	.Tile_X11Y2_RES2_O1(E_RES2[30]),
	.Tile_X11Y2_RES2_O2(E_RES2[29]),
	.Tile_X11Y2_RES2_O3(E_RES2[28]),
	.Tile_X11Y3_RES2_O0(E_RES2[27]),
	.Tile_X11Y3_RES2_O1(E_RES2[26]),
	.Tile_X11Y3_RES2_O2(E_RES2[25]),
	.Tile_X11Y3_RES2_O3(E_RES2[24]),
	.Tile_X11Y4_RES2_O0(E_RES2[23]),
	.Tile_X11Y4_RES2_O1(E_RES2[22]),
	.Tile_X11Y4_RES2_O2(E_RES2[21]),
	.Tile_X11Y4_RES2_O3(E_RES2[20]),
	.Tile_X11Y5_RES2_O0(E_RES2[19]),
	.Tile_X11Y5_RES2_O1(E_RES2[18]),
	.Tile_X11Y5_RES2_O2(E_RES2[17]),
	.Tile_X11Y5_RES2_O3(E_RES2[16]),
	.Tile_X11Y6_RES2_O0(E_RES2[15]),
	.Tile_X11Y6_RES2_O1(E_RES2[14]),
	.Tile_X11Y6_RES2_O2(E_RES2[13]),
	.Tile_X11Y6_RES2_O3(E_RES2[12]),
	.Tile_X11Y7_RES2_O0(E_RES2[11]),
	.Tile_X11Y7_RES2_O1(E_RES2[10]),
	.Tile_X11Y7_RES2_O2(E_RES2[9]),
	.Tile_X11Y7_RES2_O3(E_RES2[8]),
	.Tile_X11Y8_RES2_O0(E_RES2[7]),
	.Tile_X11Y8_RES2_O1(E_RES2[6]),
	.Tile_X11Y8_RES2_O2(E_RES2[5]),
	.Tile_X11Y8_RES2_O3(E_RES2[4]),
	.Tile_X11Y9_RES2_O0(E_RES2[3]),
	.Tile_X11Y9_RES2_O1(E_RES2[2]),
	.Tile_X11Y9_RES2_O2(E_RES2[1]),
	.Tile_X11Y9_RES2_O3(E_RES2[0]),

	.Tile_X14Y10_RAM2FAB_D0_I0(RAM2FAB_D[79]),
	.Tile_X14Y10_RAM2FAB_D0_I1(RAM2FAB_D[78]),
	.Tile_X14Y10_RAM2FAB_D0_I2(RAM2FAB_D[77]),
	.Tile_X14Y10_RAM2FAB_D0_I3(RAM2FAB_D[76]),
	.Tile_X14Y10_RAM2FAB_D1_I0(RAM2FAB_D[75]),
	.Tile_X14Y10_RAM2FAB_D1_I1(RAM2FAB_D[74]),
	.Tile_X14Y10_RAM2FAB_D1_I2(RAM2FAB_D[73]),
	.Tile_X14Y10_RAM2FAB_D1_I3(RAM2FAB_D[72]),
	.Tile_X14Y10_RAM2FAB_D2_I0(RAM2FAB_D[71]),
	.Tile_X14Y10_RAM2FAB_D2_I1(RAM2FAB_D[70]),
	.Tile_X14Y10_RAM2FAB_D2_I2(RAM2FAB_D[69]),
	.Tile_X14Y10_RAM2FAB_D2_I3(RAM2FAB_D[68]),
	.Tile_X14Y10_RAM2FAB_D3_I0(RAM2FAB_D[67]),
	.Tile_X14Y10_RAM2FAB_D3_I1(RAM2FAB_D[66]),
	.Tile_X14Y10_RAM2FAB_D3_I2(RAM2FAB_D[65]),
	.Tile_X14Y10_RAM2FAB_D3_I3(RAM2FAB_D[64]),
	.Tile_X14Y11_RAM2FAB_D0_I0(RAM2FAB_D[63]),
	.Tile_X14Y11_RAM2FAB_D0_I1(RAM2FAB_D[62]),
	.Tile_X14Y11_RAM2FAB_D0_I2(RAM2FAB_D[61]),
	.Tile_X14Y11_RAM2FAB_D0_I3(RAM2FAB_D[60]),
	.Tile_X14Y11_RAM2FAB_D1_I0(RAM2FAB_D[59]),
	.Tile_X14Y11_RAM2FAB_D1_I1(RAM2FAB_D[58]),
	.Tile_X14Y11_RAM2FAB_D1_I2(RAM2FAB_D[57]),
	.Tile_X14Y11_RAM2FAB_D1_I3(RAM2FAB_D[56]),
	.Tile_X14Y11_RAM2FAB_D2_I0(RAM2FAB_D[55]),
	.Tile_X14Y11_RAM2FAB_D2_I1(RAM2FAB_D[54]),
	.Tile_X14Y11_RAM2FAB_D2_I2(RAM2FAB_D[53]),
	.Tile_X14Y11_RAM2FAB_D2_I3(RAM2FAB_D[52]),
	.Tile_X14Y11_RAM2FAB_D3_I0(RAM2FAB_D[51]),
	.Tile_X14Y11_RAM2FAB_D3_I1(RAM2FAB_D[50]),
	.Tile_X14Y11_RAM2FAB_D3_I2(RAM2FAB_D[49]),
	.Tile_X14Y11_RAM2FAB_D3_I3(RAM2FAB_D[48]),
	.Tile_X14Y12_RAM2FAB_D0_I0(RAM2FAB_D[47]),
	.Tile_X14Y12_RAM2FAB_D0_I1(RAM2FAB_D[46]),
	.Tile_X14Y12_RAM2FAB_D0_I2(RAM2FAB_D[45]),
	.Tile_X14Y12_RAM2FAB_D0_I3(RAM2FAB_D[44]),
	.Tile_X14Y12_RAM2FAB_D1_I0(RAM2FAB_D[43]),
	.Tile_X14Y12_RAM2FAB_D1_I1(RAM2FAB_D[42]),
	.Tile_X14Y12_RAM2FAB_D1_I2(RAM2FAB_D[41]),
	.Tile_X14Y12_RAM2FAB_D1_I3(RAM2FAB_D[40]),
	.Tile_X14Y12_RAM2FAB_D2_I0(RAM2FAB_D[39]),
	.Tile_X14Y12_RAM2FAB_D2_I1(RAM2FAB_D[38]),
	.Tile_X14Y12_RAM2FAB_D2_I2(RAM2FAB_D[37]),
	.Tile_X14Y12_RAM2FAB_D2_I3(RAM2FAB_D[36]),
	.Tile_X14Y12_RAM2FAB_D3_I0(RAM2FAB_D[35]),
	.Tile_X14Y12_RAM2FAB_D3_I1(RAM2FAB_D[34]),
	.Tile_X14Y12_RAM2FAB_D3_I2(RAM2FAB_D[33]),
	.Tile_X14Y12_RAM2FAB_D3_I3(RAM2FAB_D[32]),
	.Tile_X14Y13_RAM2FAB_D0_I0(RAM2FAB_D[31]),
	.Tile_X14Y13_RAM2FAB_D0_I1(RAM2FAB_D[30]),
	.Tile_X14Y13_RAM2FAB_D0_I2(RAM2FAB_D[29]),
	.Tile_X14Y13_RAM2FAB_D0_I3(RAM2FAB_D[28]),
	.Tile_X14Y13_RAM2FAB_D1_I0(RAM2FAB_D[27]),
	.Tile_X14Y13_RAM2FAB_D1_I1(RAM2FAB_D[26]),
	.Tile_X14Y13_RAM2FAB_D1_I2(RAM2FAB_D[25]),
	.Tile_X14Y13_RAM2FAB_D1_I3(RAM2FAB_D[24]),
	.Tile_X14Y13_RAM2FAB_D2_I0(RAM2FAB_D[23]),
	.Tile_X14Y13_RAM2FAB_D2_I1(RAM2FAB_D[22]),
	.Tile_X14Y13_RAM2FAB_D2_I2(RAM2FAB_D[21]),
	.Tile_X14Y13_RAM2FAB_D2_I3(RAM2FAB_D[20]),
	.Tile_X14Y13_RAM2FAB_D3_I0(RAM2FAB_D[19]),
	.Tile_X14Y13_RAM2FAB_D3_I1(RAM2FAB_D[18]),
	.Tile_X14Y13_RAM2FAB_D3_I2(RAM2FAB_D[17]),
	.Tile_X14Y13_RAM2FAB_D3_I3(RAM2FAB_D[16]),
	.Tile_X14Y14_RAM2FAB_D0_I0(RAM2FAB_D[15]),
	.Tile_X14Y14_RAM2FAB_D0_I1(RAM2FAB_D[14]),
	.Tile_X14Y14_RAM2FAB_D0_I2(RAM2FAB_D[13]),
	.Tile_X14Y14_RAM2FAB_D0_I3(RAM2FAB_D[12]),
	.Tile_X14Y14_RAM2FAB_D1_I0(RAM2FAB_D[11]),
	.Tile_X14Y14_RAM2FAB_D1_I1(RAM2FAB_D[10]),
	.Tile_X14Y14_RAM2FAB_D1_I2(RAM2FAB_D[9]),
	.Tile_X14Y14_RAM2FAB_D1_I3(RAM2FAB_D[8]),
	.Tile_X14Y14_RAM2FAB_D2_I0(RAM2FAB_D[7]),
	.Tile_X14Y14_RAM2FAB_D2_I1(RAM2FAB_D[6]),
	.Tile_X14Y14_RAM2FAB_D2_I2(RAM2FAB_D[5]),
	.Tile_X14Y14_RAM2FAB_D2_I3(RAM2FAB_D[4]),
	.Tile_X14Y14_RAM2FAB_D3_I0(RAM2FAB_D[3]),
	.Tile_X14Y14_RAM2FAB_D3_I1(RAM2FAB_D[2]),
	.Tile_X14Y14_RAM2FAB_D3_I2(RAM2FAB_D[1]),
	.Tile_X14Y14_RAM2FAB_D3_I3(RAM2FAB_D[0]),

	.Tile_X14Y10_FAB2RAM_D0_O0(FAB2RAM_D[79]),
	.Tile_X14Y10_FAB2RAM_D0_O1(FAB2RAM_D[78]),
	.Tile_X14Y10_FAB2RAM_D0_O2(FAB2RAM_D[77]),
	.Tile_X14Y10_FAB2RAM_D0_O3(FAB2RAM_D[76]),
	.Tile_X14Y10_FAB2RAM_D1_O0(FAB2RAM_D[75]),
	.Tile_X14Y10_FAB2RAM_D1_O1(FAB2RAM_D[74]),
	.Tile_X14Y10_FAB2RAM_D1_O2(FAB2RAM_D[73]),
	.Tile_X14Y10_FAB2RAM_D1_O3(FAB2RAM_D[72]),
	.Tile_X14Y10_FAB2RAM_D2_O0(FAB2RAM_D[71]),
	.Tile_X14Y10_FAB2RAM_D2_O1(FAB2RAM_D[70]),
	.Tile_X14Y10_FAB2RAM_D2_O2(FAB2RAM_D[69]),
	.Tile_X14Y10_FAB2RAM_D2_O3(FAB2RAM_D[68]),
	.Tile_X14Y10_FAB2RAM_D3_O0(FAB2RAM_D[67]),
	.Tile_X14Y10_FAB2RAM_D3_O1(FAB2RAM_D[66]),
	.Tile_X14Y10_FAB2RAM_D3_O2(FAB2RAM_D[65]),
	.Tile_X14Y10_FAB2RAM_D3_O3(FAB2RAM_D[64]),
	.Tile_X14Y11_FAB2RAM_D0_O0(FAB2RAM_D[63]),
	.Tile_X14Y11_FAB2RAM_D0_O1(FAB2RAM_D[62]),
	.Tile_X14Y11_FAB2RAM_D0_O2(FAB2RAM_D[61]),
	.Tile_X14Y11_FAB2RAM_D0_O3(FAB2RAM_D[60]),
	.Tile_X14Y11_FAB2RAM_D1_O0(FAB2RAM_D[59]),
	.Tile_X14Y11_FAB2RAM_D1_O1(FAB2RAM_D[58]),
	.Tile_X14Y11_FAB2RAM_D1_O2(FAB2RAM_D[57]),
	.Tile_X14Y11_FAB2RAM_D1_O3(FAB2RAM_D[56]),
	.Tile_X14Y11_FAB2RAM_D2_O0(FAB2RAM_D[55]),
	.Tile_X14Y11_FAB2RAM_D2_O1(FAB2RAM_D[54]),
	.Tile_X14Y11_FAB2RAM_D2_O2(FAB2RAM_D[53]),
	.Tile_X14Y11_FAB2RAM_D2_O3(FAB2RAM_D[52]),
	.Tile_X14Y11_FAB2RAM_D3_O0(FAB2RAM_D[51]),
	.Tile_X14Y11_FAB2RAM_D3_O1(FAB2RAM_D[50]),
	.Tile_X14Y11_FAB2RAM_D3_O2(FAB2RAM_D[49]),
	.Tile_X14Y11_FAB2RAM_D3_O3(FAB2RAM_D[48]),
	.Tile_X14Y12_FAB2RAM_D0_O0(FAB2RAM_D[47]),
	.Tile_X14Y12_FAB2RAM_D0_O1(FAB2RAM_D[46]),
	.Tile_X14Y12_FAB2RAM_D0_O2(FAB2RAM_D[45]),
	.Tile_X14Y12_FAB2RAM_D0_O3(FAB2RAM_D[44]),
	.Tile_X14Y12_FAB2RAM_D1_O0(FAB2RAM_D[43]),
	.Tile_X14Y12_FAB2RAM_D1_O1(FAB2RAM_D[42]),
	.Tile_X14Y12_FAB2RAM_D1_O2(FAB2RAM_D[41]),
	.Tile_X14Y12_FAB2RAM_D1_O3(FAB2RAM_D[40]),
	.Tile_X14Y12_FAB2RAM_D2_O0(FAB2RAM_D[39]),
	.Tile_X14Y12_FAB2RAM_D2_O1(FAB2RAM_D[38]),
	.Tile_X14Y12_FAB2RAM_D2_O2(FAB2RAM_D[37]),
	.Tile_X14Y12_FAB2RAM_D2_O3(FAB2RAM_D[36]),
	.Tile_X14Y12_FAB2RAM_D3_O0(FAB2RAM_D[35]),
	.Tile_X14Y12_FAB2RAM_D3_O1(FAB2RAM_D[34]),
	.Tile_X14Y12_FAB2RAM_D3_O2(FAB2RAM_D[33]),
	.Tile_X14Y12_FAB2RAM_D3_O3(FAB2RAM_D[32]),
	.Tile_X14Y13_FAB2RAM_D0_O0(FAB2RAM_D[31]),
	.Tile_X14Y13_FAB2RAM_D0_O1(FAB2RAM_D[30]),
	.Tile_X14Y13_FAB2RAM_D0_O2(FAB2RAM_D[29]),
	.Tile_X14Y13_FAB2RAM_D0_O3(FAB2RAM_D[28]),
	.Tile_X14Y13_FAB2RAM_D1_O0(FAB2RAM_D[27]),
	.Tile_X14Y13_FAB2RAM_D1_O1(FAB2RAM_D[26]),
	.Tile_X14Y13_FAB2RAM_D1_O2(FAB2RAM_D[25]),
	.Tile_X14Y13_FAB2RAM_D1_O3(FAB2RAM_D[24]),
	.Tile_X14Y13_FAB2RAM_D2_O0(FAB2RAM_D[23]),
	.Tile_X14Y13_FAB2RAM_D2_O1(FAB2RAM_D[22]),
	.Tile_X14Y13_FAB2RAM_D2_O2(FAB2RAM_D[21]),
	.Tile_X14Y13_FAB2RAM_D2_O3(FAB2RAM_D[20]),
	.Tile_X14Y13_FAB2RAM_D3_O0(FAB2RAM_D[19]),
	.Tile_X14Y13_FAB2RAM_D3_O1(FAB2RAM_D[18]),
	.Tile_X14Y13_FAB2RAM_D3_O2(FAB2RAM_D[17]),
	.Tile_X14Y13_FAB2RAM_D3_O3(FAB2RAM_D[16]),
	.Tile_X14Y14_FAB2RAM_D0_O0(FAB2RAM_D[15]),
	.Tile_X14Y14_FAB2RAM_D0_O1(FAB2RAM_D[14]),
	.Tile_X14Y14_FAB2RAM_D0_O2(FAB2RAM_D[13]),
	.Tile_X14Y14_FAB2RAM_D0_O3(FAB2RAM_D[12]),
	.Tile_X14Y14_FAB2RAM_D1_O0(FAB2RAM_D[11]),
	.Tile_X14Y14_FAB2RAM_D1_O1(FAB2RAM_D[10]),
	.Tile_X14Y14_FAB2RAM_D1_O2(FAB2RAM_D[9]),
	.Tile_X14Y14_FAB2RAM_D1_O3(FAB2RAM_D[8]),
	.Tile_X14Y14_FAB2RAM_D2_O0(FAB2RAM_D[7]),
	.Tile_X14Y14_FAB2RAM_D2_O1(FAB2RAM_D[6]),
	.Tile_X14Y14_FAB2RAM_D2_O2(FAB2RAM_D[5]),
	.Tile_X14Y14_FAB2RAM_D2_O3(FAB2RAM_D[4]),
	.Tile_X14Y14_FAB2RAM_D3_O0(FAB2RAM_D[3]),
	.Tile_X14Y14_FAB2RAM_D3_O1(FAB2RAM_D[2]),
	.Tile_X14Y14_FAB2RAM_D3_O2(FAB2RAM_D[1]),
	.Tile_X14Y14_FAB2RAM_D3_O3(FAB2RAM_D[0]),

	.Tile_X14Y10_FAB2RAM_A0_O0(FAB2RAM_A[39]),
	.Tile_X14Y10_FAB2RAM_A0_O1(FAB2RAM_A[38]),
	.Tile_X14Y10_FAB2RAM_A0_O2(FAB2RAM_A[37]),
	.Tile_X14Y10_FAB2RAM_A0_O3(FAB2RAM_A[36]),
	.Tile_X14Y10_FAB2RAM_A1_O0(FAB2RAM_A[35]),
	.Tile_X14Y10_FAB2RAM_A1_O1(FAB2RAM_A[34]),
	.Tile_X14Y10_FAB2RAM_A1_O2(FAB2RAM_A[33]),
	.Tile_X14Y10_FAB2RAM_A1_O3(FAB2RAM_A[32]),
	.Tile_X14Y11_FAB2RAM_A0_O0(FAB2RAM_A[31]),
	.Tile_X14Y11_FAB2RAM_A0_O1(FAB2RAM_A[30]),
	.Tile_X14Y11_FAB2RAM_A0_O2(FAB2RAM_A[29]),
	.Tile_X14Y11_FAB2RAM_A0_O3(FAB2RAM_A[28]),
	.Tile_X14Y11_FAB2RAM_A1_O0(FAB2RAM_A[27]),
	.Tile_X14Y11_FAB2RAM_A1_O1(FAB2RAM_A[26]),
	.Tile_X14Y11_FAB2RAM_A1_O2(FAB2RAM_A[25]),
	.Tile_X14Y11_FAB2RAM_A1_O3(FAB2RAM_A[24]),
	.Tile_X14Y12_FAB2RAM_A0_O0(FAB2RAM_A[23]),
	.Tile_X14Y12_FAB2RAM_A0_O1(FAB2RAM_A[22]),
	.Tile_X14Y12_FAB2RAM_A0_O2(FAB2RAM_A[21]),
	.Tile_X14Y12_FAB2RAM_A0_O3(FAB2RAM_A[20]),
	.Tile_X14Y12_FAB2RAM_A1_O0(FAB2RAM_A[19]),
	.Tile_X14Y12_FAB2RAM_A1_O1(FAB2RAM_A[18]),
	.Tile_X14Y12_FAB2RAM_A1_O2(FAB2RAM_A[17]),
	.Tile_X14Y12_FAB2RAM_A1_O3(FAB2RAM_A[16]),
	.Tile_X14Y13_FAB2RAM_A0_O0(FAB2RAM_A[15]),
	.Tile_X14Y13_FAB2RAM_A0_O1(FAB2RAM_A[14]),
	.Tile_X14Y13_FAB2RAM_A0_O2(FAB2RAM_A[13]),
	.Tile_X14Y13_FAB2RAM_A0_O3(FAB2RAM_A[12]),
	.Tile_X14Y13_FAB2RAM_A1_O0(FAB2RAM_A[11]),
	.Tile_X14Y13_FAB2RAM_A1_O1(FAB2RAM_A[10]),
	.Tile_X14Y13_FAB2RAM_A1_O2(FAB2RAM_A[9]),
	.Tile_X14Y13_FAB2RAM_A1_O3(FAB2RAM_A[8]),
	.Tile_X14Y14_FAB2RAM_A0_O0(FAB2RAM_A[7]),
	.Tile_X14Y14_FAB2RAM_A0_O1(FAB2RAM_A[6]),
	.Tile_X14Y14_FAB2RAM_A0_O2(FAB2RAM_A[5]),
	.Tile_X14Y14_FAB2RAM_A0_O3(FAB2RAM_A[4]),
	.Tile_X14Y14_FAB2RAM_A1_O0(FAB2RAM_A[3]),
	.Tile_X14Y14_FAB2RAM_A1_O1(FAB2RAM_A[2]),
	.Tile_X14Y14_FAB2RAM_A1_O2(FAB2RAM_A[1]),
	.Tile_X14Y14_FAB2RAM_A1_O3(FAB2RAM_A[0]),

	.Tile_X14Y10_FAB2RAM_C_O0(FAB2RAM_C[19]),
	.Tile_X14Y10_FAB2RAM_C_O1(FAB2RAM_C[18]),
	.Tile_X14Y10_FAB2RAM_C_O2(FAB2RAM_C[17]),
	.Tile_X14Y10_FAB2RAM_C_O3(FAB2RAM_C[16]),
	.Tile_X14Y11_FAB2RAM_C_O0(FAB2RAM_C[15]),
	.Tile_X14Y11_FAB2RAM_C_O1(FAB2RAM_C[14]),
	.Tile_X14Y11_FAB2RAM_C_O2(FAB2RAM_C[13]),
	.Tile_X14Y11_FAB2RAM_C_O3(FAB2RAM_C[12]),
	.Tile_X14Y12_FAB2RAM_C_O0(FAB2RAM_C[11]),
	.Tile_X14Y12_FAB2RAM_C_O1(FAB2RAM_C[10]),
	.Tile_X14Y12_FAB2RAM_C_O2(FAB2RAM_C[9]),
	.Tile_X14Y12_FAB2RAM_C_O3(FAB2RAM_C[8]),
	.Tile_X14Y13_FAB2RAM_C_O0(FAB2RAM_C[7]),
	.Tile_X14Y13_FAB2RAM_C_O1(FAB2RAM_C[6]),
	.Tile_X14Y13_FAB2RAM_C_O2(FAB2RAM_C[5]),
	.Tile_X14Y13_FAB2RAM_C_O3(FAB2RAM_C[4]),
	.Tile_X14Y14_FAB2RAM_C_O0(FAB2RAM_C[3]),
	.Tile_X14Y14_FAB2RAM_C_O1(FAB2RAM_C[2]),
	.Tile_X14Y14_FAB2RAM_C_O2(FAB2RAM_C[1]),
	.Tile_X14Y14_FAB2RAM_C_O3(FAB2RAM_C[0]),

	.Tile_X14Y10_Config_accessC_bit0(Config_accessC[19]),
	.Tile_X14Y10_Config_accessC_bit1(Config_accessC[18]),
	.Tile_X14Y10_Config_accessC_bit2(Config_accessC[17]),
	.Tile_X14Y10_Config_accessC_bit3(Config_accessC[16]),
	.Tile_X14Y11_Config_accessC_bit0(Config_accessC[15]),
	.Tile_X14Y11_Config_accessC_bit1(Config_accessC[14]),
	.Tile_X14Y11_Config_accessC_bit2(Config_accessC[13]),
	.Tile_X14Y11_Config_accessC_bit3(Config_accessC[12]),
	.Tile_X14Y12_Config_accessC_bit0(Config_accessC[11]),
	.Tile_X14Y12_Config_accessC_bit1(Config_accessC[10]),
	.Tile_X14Y12_Config_accessC_bit2(Config_accessC[9]),
	.Tile_X14Y12_Config_accessC_bit3(Config_accessC[8]),
	.Tile_X14Y13_Config_accessC_bit0(Config_accessC[7]),
	.Tile_X14Y13_Config_accessC_bit1(Config_accessC[6]),
	.Tile_X14Y13_Config_accessC_bit2(Config_accessC[5]),
	.Tile_X14Y13_Config_accessC_bit3(Config_accessC[4]),
	.Tile_X14Y14_Config_accessC_bit0(Config_accessC[3]),
	.Tile_X14Y14_Config_accessC_bit1(Config_accessC[2]),
	.Tile_X14Y14_Config_accessC_bit2(Config_accessC[1]),
	.Tile_X14Y14_Config_accessC_bit3(Config_accessC[0]),

	//declarations
	.UserCLK(CLK),
	.FrameData(FrameData),
	.FrameStrobe(FrameSelect)
	);

	assign FrameData = {32'h12345678,FrameRegister,32'h12345678};

endmodule

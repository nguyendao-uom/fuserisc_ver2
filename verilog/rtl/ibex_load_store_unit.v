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

module ibex_load_store_unit (
	clk,
	rst_n,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_err_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_rdata_i,
	data_we_ex_i,
	data_type_ex_i,
	data_wdata_ex_i,
	data_reg_offset_ex_i,
	data_sign_ext_ex_i,
	data_rdata_ex_o,
	data_req_ex_i,
	adder_result_ex_i,
	data_misaligned_o,
	misaligned_addr_o,
	load_err_o,
	store_err_o,
	lsu_update_addr_o,
	data_valid_o,
	busy_o
);
	input wire clk;
	input wire rst_n;
	output reg data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_err_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	input wire data_we_ex_i;
	input wire [1:0] data_type_ex_i;
	input wire [31:0] data_wdata_ex_i;
	input wire [1:0] data_reg_offset_ex_i;
	input wire data_sign_ext_ex_i;
	output wire [31:0] data_rdata_ex_o;
	input wire data_req_ex_i;
	input wire [31:0] adder_result_ex_i;
	output reg data_misaligned_o;
	output reg [31:0] misaligned_addr_o;
	output wire load_err_o;
	output wire store_err_o;
	output reg lsu_update_addr_o;
	output reg data_valid_o;
	output wire busy_o;
	wire [31:0] data_addr_int;
	reg [1:0] data_type_q;
	reg [1:0] rdata_offset_q;
	reg data_sign_ext_q;
	reg data_we_q;
	wire [1:0] wdata_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata;
	wire misaligned_st;
	reg data_misaligned;
	reg data_misaligned_q;
	reg increase_address;
	reg [2:0] CS;
	reg [2:0] NS;
	reg [31:0] rdata_q;
	always @(*)
		case (data_type_ex_i)
			2'b00:
				if (!misaligned_st)
					case (data_addr_int[1:0])
						2'b00: data_be = 4'b1111;
						2'b01: data_be = 4'b1110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
					endcase
				else
					case (data_addr_int[1:0])
						2'b00: data_be = 4'b0000;
						2'b01: data_be = 4'b0001;
						2'b10: data_be = 4'b0011;
						2'b11: data_be = 4'b0111;
					endcase
			2'b01:
				if (!misaligned_st)
					case (data_addr_int[1:0])
						2'b00: data_be = 4'b0011;
						2'b01: data_be = 4'b0110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
					endcase
				else
					data_be = 4'b0001;
			2'b10, 2'b11:
				case (data_addr_int[1:0])
					2'b00: data_be = 4'b0001;
					2'b01: data_be = 4'b0010;
					2'b10: data_be = 4'b0100;
					2'b11: data_be = 4'b1000;
				endcase
		endcase
	assign wdata_offset = data_addr_int[1:0] - data_reg_offset_ex_i[1:0];
	always @(*)
		case (wdata_offset)
			2'b00: data_wdata = data_wdata_ex_i[31:0];
			2'b01: data_wdata = {data_wdata_ex_i[23:0], data_wdata_ex_i[31:24]};
			2'b10: data_wdata = {data_wdata_ex_i[15:0], data_wdata_ex_i[31:16]};
			2'b11: data_wdata = {data_wdata_ex_i[7:0], data_wdata_ex_i[31:8]};
		endcase
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			data_type_q <= 2'h0;
			rdata_offset_q <= 2'h0;
			data_sign_ext_q <= 1'b0;
			data_we_q <= 1'b0;
		end
		else if (data_gnt_i) begin
			data_type_q <= data_type_ex_i;
			rdata_offset_q <= data_addr_int[1:0];
			data_sign_ext_q <= data_sign_ext_ex_i;
			data_we_q <= data_we_ex_i;
		end
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	always @(*)
		case (rdata_offset_q)
			2'b00: rdata_w_ext = data_rdata_i[31:0];
			2'b01: rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
		endcase
	always @(*)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
				else
					rdata_h_ext = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
				else
					rdata_h_ext = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
				else
					rdata_h_ext = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
		endcase
	always @(*)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
				else
					rdata_b_ext = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[15:8]};
				else
					rdata_b_ext = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[23:16]};
				else
					rdata_b_ext = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[31:24]};
				else
					rdata_b_ext = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
		endcase
	always @(*)
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
		endcase
	localparam [2:0] IDLE = 0;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			CS <= IDLE;
			rdata_q <= {32 {1'sb0}};
			data_misaligned_q <= 1'b0;
			misaligned_addr_o <= 32'b00000000000000000000000000000000;
		end
		else begin
			CS <= NS;
			if (lsu_update_addr_o) begin
				data_misaligned_q <= data_misaligned;
				if (increase_address)
					misaligned_addr_o <= data_addr_int;
			end
			if (data_rvalid_i && !data_we_q)
				if (data_misaligned_q || data_misaligned)
					rdata_q <= data_rdata_i;
				else
					rdata_q <= data_rdata_ext;
		end
	assign data_rdata_ex_o = (data_rvalid_i ? data_rdata_ext : rdata_q);
	assign data_addr_o = data_addr_int;
	assign data_wdata_o = data_wdata;
	assign data_we_o = data_we_ex_i;
	assign data_be_o = data_be;
	assign misaligned_st = data_misaligned_q;
	assign load_err_o = 1'b0;
	assign store_err_o = 1'b0;
	localparam [2:0] WAIT_GNT = 3;
	localparam [2:0] WAIT_GNT_MIS = 1;
	localparam [2:0] WAIT_RVALID = 4;
	localparam [2:0] WAIT_RVALID_MIS = 2;
	always @(*) begin
		NS = CS;
		data_req_o = 1'b0;
		lsu_update_addr_o = 1'b0;
		data_valid_o = 1'b0;
		increase_address = 1'b0;
		data_misaligned_o = 1'b0;
		case (CS)
			IDLE:
				if (data_req_ex_i) begin
					data_req_o = data_req_ex_i;
					if (data_gnt_i) begin
						lsu_update_addr_o = 1'b1;
						increase_address = data_misaligned;
						NS = (data_misaligned ? WAIT_RVALID_MIS : WAIT_RVALID);
					end
					else
						NS = (data_misaligned ? WAIT_GNT_MIS : WAIT_GNT);
				end
			WAIT_GNT_MIS: begin
				data_req_o = 1'b1;
				if (data_gnt_i) begin
					lsu_update_addr_o = 1'b1;
					increase_address = data_misaligned;
					NS = WAIT_RVALID_MIS;
				end
			end
			WAIT_RVALID_MIS: begin
				increase_address = 1'b0;
				data_misaligned_o = 1'b1;
				data_req_o = 1'b0;
				lsu_update_addr_o = data_gnt_i;
				if (data_rvalid_i) begin
					data_req_o = 1'b1;
					if (data_gnt_i)
						NS = WAIT_RVALID;
					else
						NS = WAIT_GNT;
				end
				else
					NS = WAIT_RVALID_MIS;
			end
			WAIT_GNT: begin
				data_misaligned_o = data_misaligned_q;
				data_req_o = 1'b1;
				if (data_gnt_i) begin
					lsu_update_addr_o = 1'b1;
					NS = WAIT_RVALID;
				end
			end
			WAIT_RVALID: begin
				data_req_o = 1'b0;
				if (data_rvalid_i) begin
					data_valid_o = 1'b1;
					NS = IDLE;
				end
				else
					NS = WAIT_RVALID;
			end
			default: NS = IDLE;
		endcase
	end
	always @(*) begin
		data_misaligned = 1'b0;
		if (data_req_ex_i && !data_misaligned_q)
			case (data_type_ex_i)
				2'b00:
					if (data_addr_int[1:0] != 2'b00)
						data_misaligned = 1'b1;
				2'b01:
					if (data_addr_int[1:0] == 2'b11)
						data_misaligned = 1'b1;
				default:
					;
			endcase
	end
	assign data_addr_int = adder_result_ex_i;
	assign busy_o = (CS == WAIT_RVALID) | (data_req_o == 1'b1);
endmodule

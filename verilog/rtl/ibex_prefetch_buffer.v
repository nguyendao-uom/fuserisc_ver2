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

module ibex_prefetch_buffer (
	clk,
	rst_n,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rvalid_i,
	busy_o
);
	input wire clk;
	input wire rst_n;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output reg instr_req_o;
	input wire instr_gnt_i;
	output reg [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_rvalid_i;
	output wire busy_o;
	reg [1:0] CS;
	reg [1:0] NS;
	reg [31:0] instr_addr_q;
	wire [31:0] fetch_addr;
	reg addr_valid;
	reg fifo_valid;
	wire fifo_ready;
	wire fifo_clear;
	localparam [1:0] IDLE = 0;
	assign busy_o = (CS != IDLE) | instr_req_o;
	ibex_fetch_fifo fifo_i(
		.clk(clk),
		.rst_n(rst_n),
		.clear_i(fifo_clear),
		.in_addr_i(instr_addr_q),
		.in_rdata_i(instr_rdata_i),
		.in_valid_i(fifo_valid),
		.in_ready_o(fifo_ready),
		.out_valid_o(valid_o),
		.out_ready_i(ready_i),
		.out_rdata_o(rdata_o),
		.out_addr_o(addr_o),
		.out_valid_stored_o()
	);
	assign fetch_addr = {instr_addr_q[31:2], 2'b00} + 32'd4;
	assign fifo_clear = branch_i;
	localparam [1:0] WAIT_ABORTED = 3;
	localparam [1:0] WAIT_GNT = 1;
	localparam [1:0] WAIT_RVALID = 2;
	always @(*) begin
		instr_req_o = 1'b0;
		instr_addr_o = fetch_addr;
		fifo_valid = 1'b0;
		addr_valid = 1'b0;
		NS = CS;
		case (CS)
			IDLE: begin
				instr_addr_o = fetch_addr;
				instr_req_o = 1'b0;
				if (branch_i)
					instr_addr_o = addr_i;
				if (req_i && (fifo_ready || branch_i)) begin
					instr_req_o = 1'b1;
					addr_valid = 1'b1;
					NS = (instr_gnt_i ? WAIT_RVALID : WAIT_GNT);
				end
			end
			WAIT_GNT: begin
				instr_addr_o = instr_addr_q;
				instr_req_o = 1'b1;
				if (branch_i) begin
					instr_addr_o = addr_i;
					addr_valid = 1'b1;
				end
				NS = (instr_gnt_i ? WAIT_RVALID : WAIT_GNT);
			end
			WAIT_RVALID: begin
				instr_addr_o = fetch_addr;
				if (branch_i)
					instr_addr_o = addr_i;
				if (req_i && (fifo_ready || branch_i)) begin
					if (instr_rvalid_i) begin
						instr_req_o = 1'b1;
						fifo_valid = 1'b1;
						addr_valid = 1'b1;
						NS = (instr_gnt_i ? WAIT_RVALID : WAIT_GNT);
					end
					else if (branch_i) begin
						addr_valid = 1'b1;
						NS = WAIT_ABORTED;
					end
				end
				else if (instr_rvalid_i) begin
					fifo_valid = 1'b1;
					NS = IDLE;
				end
			end
			WAIT_ABORTED: begin
				instr_addr_o = instr_addr_q;
				if (branch_i) begin
					instr_addr_o = addr_i;
					addr_valid = 1'b1;
				end
				if (instr_rvalid_i) begin
					instr_req_o = 1'b1;
					NS = (instr_gnt_i ? WAIT_RVALID : WAIT_GNT);
				end
			end
			default:
				;
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			CS <= IDLE;
			instr_addr_q <= {32 {1'sb0}};
		end
		else begin
			CS <= NS;
			if (addr_valid)
				instr_addr_q <= instr_addr_o;
		end
endmodule

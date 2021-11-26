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

module ibex_int_controller (
	clk,
	rst_n,
	irq_req_ctrl_o,
	irq_id_ctrl_o,
	ctrl_ack_i,
	ctrl_kill_i,
	irq_i,
	irq_id_i,
	m_IE_i
);
	input wire clk;
	input wire rst_n;
	output wire irq_req_ctrl_o;
	output wire [4:0] irq_id_ctrl_o;
	input wire ctrl_ack_i;
	input wire ctrl_kill_i;
	input wire irq_i;
	input wire [4:0] irq_id_i;
	input wire m_IE_i;
	reg [1:0] exc_ctrl_ns;
	reg [1:0] exc_ctrl_cs;
	wire irq_enable_ext;
	reg [4:0] irq_id_d;
	reg [4:0] irq_id_q;
	assign irq_enable_ext = m_IE_i;
	localparam [1:0] IRQ_PENDING = 1;
	assign irq_req_ctrl_o = exc_ctrl_cs == IRQ_PENDING;
	assign irq_id_ctrl_o = irq_id_q;
	localparam [1:0] IDLE = 0;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			irq_id_q <= {5 {1'sb0}};
			exc_ctrl_cs <= IDLE;
		end
		else begin
			irq_id_q <= irq_id_d;
			exc_ctrl_cs <= exc_ctrl_ns;
		end
	localparam [1:0] IRQ_DONE = 2;
	always @(*) begin
		irq_id_d = irq_id_q;
		exc_ctrl_ns = exc_ctrl_cs;
		case (exc_ctrl_cs)
			IDLE:
				if (irq_enable_ext && irq_i) begin
					exc_ctrl_ns = IRQ_PENDING;
					irq_id_d = irq_id_i;
				end
			IRQ_PENDING:
				case (1'b1)
					ctrl_ack_i: exc_ctrl_ns = IRQ_DONE;
					ctrl_kill_i: exc_ctrl_ns = IDLE;
					default: exc_ctrl_ns = IRQ_PENDING;
				endcase
			IRQ_DONE: exc_ctrl_ns = IDLE;
		endcase
	end
endmodule

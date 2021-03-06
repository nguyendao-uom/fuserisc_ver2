// SPDX-FileCopyrightText: 
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
module uart_to_mem (
	clk_i,
	rst_i,
	rx_i,
	tx_o,
	data_req_o,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_rdata_i,
	data_rvalid_i,
	data_gnt_i,
	uart_error
);
	parameter ADDR_WIDTH = 12;
	input clk_i;
	input rst_i;
	input rx_i;
	output tx_o;
	output reg data_req_o;
	output [ADDR_WIDTH - 1:0] data_addr_o;
	output reg data_we_o;
	output [3:0] data_be_o;
	output [31:0] data_wdata_o;
	input reg [31:0] data_rdata_i;
	input data_rvalid_i;
	input data_gnt_i;
	output uart_error;
	assign data_be_o = 4'b1111;
	wire transmit_i;
	reg [7:0] tx_byte_i;
	wire received_o;
	wire [7:0] rx_byte_o;
	wire is_receiving_o;
	wire is_transmitting_o;
	wire recv_error_o;
	assign uart_error = recv_error_o;
	parameter IDLE = 0;
	parameter WAIT_ADDR_HEAD = 1;
	parameter WAIT_ADDR_TAIL = 2;
	parameter RECEIVE_WRITE_DATA = 3;
	parameter SEND_READ_DATA = 4;
	parameter PKT_ALIVE = 8'b00100000;
	parameter PKT_WRITE_CMD = 8'b01000001;
	parameter PKT_ADR = 8'b01100000;
	parameter PKT_READ_CMD = 8'b01000010;
	reg [2:0] UART_STATE;
	reg [31:0] DATA;
	reg [31:0] DATA_READ;
	reg [ADDR_WIDTH - 1:0] MEMORY_ADDRESS;
	assign data_wdata_o = DATA[31:0];
	assign data_addr_o[ADDR_WIDTH - 1:0] = {MEMORY_ADDRESS[ADDR_WIDTH - 1:0]};
	reg transmit;
	reg trans_txn_ff2;
	reg trans_txn_ff;
	assign transmit_i = !trans_txn_ff2 & trans_txn_ff;
	always @(posedge clk_i)
		if (rst_i) begin
			trans_txn_ff <= 1'b0;
			trans_txn_ff2 <= 1'b0;
		end
		else begin
			trans_txn_ff <= transmit;
			trans_txn_ff2 <= trans_txn_ff;
		end
	reg [2:0] data_count;
	reg we;
	reg start_read;
	reg read_issued;
	reg read_registered;
	reg read_complete;
	reg write_issued;
	reg pending_res;
	always @(posedge clk_i or posedge rst_i)
		if (rst_i) begin
			pending_res <= 0;
			UART_STATE <= IDLE;
			MEMORY_ADDRESS <= 0;
			transmit <= 0;
			data_count <= 4;
			we <= 0;
			start_read <= 0;
			DATA <= 0;
			tx_byte_i <= 0;
		end
		else
			case (UART_STATE)
				IDLE: begin
					data_count <= 4;
					start_read <= 0;
					if ((!is_transmitting_o & !received_o) & !is_receiving_o) begin
						tx_byte_i <= PKT_ALIVE;
						transmit <= 1;
					end
					else if (received_o || (pending_res == 1'b1)) begin
						if (recv_error_o == 1'b0)
							if (is_transmitting_o)
								pending_res <= 1'b1;
							else if (rx_byte_o[7:0] == PKT_WRITE_CMD[7:0]) begin
								tx_byte_i <= PKT_WRITE_CMD;
								we <= 1;
								transmit <= 1;
								pending_res <= 1'b0;
								UART_STATE <= WAIT_ADDR_HEAD;
							end
							else if (rx_byte_o[7:0] == PKT_READ_CMD[7:0]) begin
								tx_byte_i <= PKT_READ_CMD;
								$display("IDLE to WAIT_ADDR_HEAD \n");
								we <= 0;
								transmit <= 1;
								pending_res <= 1'b0;
								UART_STATE <= WAIT_ADDR_HEAD;
							end
					end
					else
						transmit <= 0;
				end
				WAIT_ADDR_HEAD:
					if (received_o) begin
						if (recv_error_o == 1'b1)
							UART_STATE <= IDLE;
						else if (rx_byte_o[7:5] == PKT_ADR[7:5]) begin
							tx_byte_i <= rx_byte_o;
							MEMORY_ADDRESS[11:8] <= rx_byte_o[3:0];
							transmit <= 1;
							UART_STATE <= WAIT_ADDR_TAIL;
							$display("WAIT_ADDR_HEAD to WAIT_ADDR_TAIL\n");
						end
					end
					else
						transmit <= 0;
				WAIT_ADDR_TAIL:
					if (received_o) begin
						MEMORY_ADDRESS[7:0] <= rx_byte_o[7:0];
						data_count <= 4;
						if (recv_error_o == 1'b1)
							UART_STATE <= IDLE;
						else if (we == 1) begin
							tx_byte_i <= rx_byte_o;
							transmit <= 1;
							UART_STATE <= RECEIVE_WRITE_DATA;
						end
						else begin
							start_read <= 1;
							$display("WAIT_ADDR_TAIL received_o\n");
						end
					end
					else if (read_issued) begin
						$display("WAIT_ADDR_TAIL READ ISSUED\n");
						start_read <= 0;
					end
					else if (read_complete) begin
						$display("WAIT_ADDR_TAIL to SEND_READ_DATA\n");
						UART_STATE <= SEND_READ_DATA;
					end
					else
						transmit <= 0;
				RECEIVE_WRITE_DATA:
					if (received_o) begin
						$display("packet recieved uart 2 mem");
						tx_byte_i <= rx_byte_o;
						if (data_count == 4) begin
							DATA[31:24] <= rx_byte_o;
							data_count <= 3;
						end
						else if (data_count == 3) begin
							DATA[23:16] <= rx_byte_o;
							data_count <= 2;
						end
						else if (data_count == 2) begin
							DATA[15:8] <= rx_byte_o;
							data_count <= 1;
						end
						else if (data_count == 1) begin
							DATA[7:0] <= rx_byte_o;
							data_count <= 0;
							UART_STATE <= IDLE;
						end
						transmit <= 1;
					end
					else
						transmit <= 0;
				SEND_READ_DATA:
					if (data_count == 4) begin
						tx_byte_i <= DATA_READ[31:24];
						transmit <= 1;
						data_count <= 3;
						$display("U2M - Sending B1 -", DATA_READ[31:24]);
					end
					else if (received_o) begin
						if (data_count == 3) begin
							tx_byte_i <= DATA_READ[23:16];
							data_count <= 2;
							$display("U2M - Sending B2 -", DATA_READ[23:16]);
						end
						else if (data_count == 2) begin
							tx_byte_i <= DATA_READ[15:8];
							data_count <= 1;
							$display("U2M - Sending B3 -", DATA_READ[15:8]);
						end
						else if (data_count == 1) begin
							tx_byte_i <= DATA_READ[7:0];
							data_count <= 0;
							$display("U2M - Sending B4 -", DATA_READ[7:0]);
						end
						else if (data_count == 0)
							UART_STATE <= IDLE;
						transmit <= 1;
					end
					else
						transmit <= 0;
			endcase
	always @(posedge clk_i)
		if (rst_i) begin
			write_issued <= 0;
			read_issued <= 0;
			read_registered <= 0;
			DATA_READ <= 0;
			data_we_o <= 0;
			data_req_o <= 0;
			read_complete <= 0;
		end
		else if (((data_count == 0) | (write_issued == 1)) & (we == 1)) begin
			if (write_issued == 0) begin
				data_we_o <= 1;
				data_req_o <= 1;
				write_issued <= 1;
			end
			else if (write_issued == 1)
				if (data_gnt_i == 1) begin
					data_req_o <= 0;
					write_issued <= 0;
				end
		end
		else if (~read_issued & (start_read == 1)) begin
			read_complete <= 0;
			data_we_o <= 0;
			data_req_o <= 1;
			read_issued <= 1;
		end
		else if ((read_issued == 1) & (data_gnt_i == 1)) begin
			data_req_o <= 0;
			read_issued <= 0;
			read_registered <= 1;
		end
		else if (read_registered == 1) begin
			if (data_rvalid_i) begin
				read_registered <= 0;
				DATA_READ <= data_rdata_i;
				read_complete <= 1;
			end
		end
		else if (read_complete == 1)
			read_complete <= 0;
	uart uart_i(
		clk_i,
		rst_i,
		rx_i,
		tx_o,
		transmit_i,
		tx_byte_i,
		received_o,
		rx_byte_o,
		is_receiving_o,
		is_transmitting_o,
		recv_error_o
	);
endmodule

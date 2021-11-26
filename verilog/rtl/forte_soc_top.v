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
`timescale 1 ps / 1 ps


//need to check the address width through the application.


module forte_soc_top #(

parameter SLAVE_ADDR_WIDTH = 10, ADDR_WIDTH=12, MASTERS=5, DATA_WIDTH=32, SLAVES=3, ROMASTERS=2, ROSLAVES=2,ROMASTER_ADDR_WIDTH=11)
   (
 
   //core 1
    debug_req_1_i,
    fetch_enable_1_i,
    irq_ack_1_o,
    irq_1_i,
    irq_id_1_i,
    irq_id_1_o,
    eFPGA_operand_a_1_o,
    eFPGA_operand_b_1_o,
    eFPGA_result_a_1_i,
    eFPGA_result_b_1_i,
    eFPGA_result_c_1_i,
    eFPGA_write_strobe_1_o,
    eFPGA_fpga_done_1_i,
    eFPGA_delay_1_o,
    eFPGA_en_1_o,
    eFPGA_operator_1_o,

//Wishbone to carvel
    wb_clk_i,
    wb_rst_i,
    wbs_stb_i,
    wbs_cyc_i,
    wbs_we_i,
    wbs_sel_i,
    wbs_dat_i,
    wbs_adr_i,
    wbs_ack_o,
    wbs_dat_o,
//core 2
    debug_req_2_i,
    fetch_enable_2_i,
    irq_ack_2_o,
    irq_2_i,
    irq_id_2_i,
    irq_id_2_o,
    eFPGA_operand_a_2_o,
    eFPGA_operand_b_2_o,
    eFPGA_result_a_2_i,
    eFPGA_result_b_2_i,
    eFPGA_result_c_2_i,
    eFPGA_write_strobe_2_o,
    eFPGA_fpga_done_2_i,
    eFPGA_delay_2_o,
    eFPGA_en_2_o,
    eFPGA_operator_2_o,
//uart pins to USER area off chip IO
    rxd_uart,
    txd_uart,
    rxd_uart_to_mem,
    txd_uart_to_mem,
    error_uart_to_mem
);

//41

    wire clk_i ; //main clock 20mhz
    assign clk_i = wb_clk_i;
    wire  reset;
    assign reset = wb_rst_i;
    input debug_req_1_i;
    input fetch_enable_1_i; //enable cpu

    output irq_ack_1_o;
    input irq_1_i;
    input [4:0]irq_id_1_i;
    output [4:0]irq_id_1_o;
    output [31:0] eFPGA_operand_a_1_o;
    output [31:0] eFPGA_operand_b_1_o;
    input [31:0] eFPGA_result_a_1_i;
    input [31:0] eFPGA_result_b_1_i;
    input [31:0] eFPGA_result_c_1_i; //total 160 pins to fpga
    output eFPGA_write_strobe_1_o;  
    input eFPGA_fpga_done_1_i; 
    output eFPGA_en_1_o;
    output [1:0] eFPGA_operator_1_o;
    output [3:0] eFPGA_delay_1_o;

    input debug_req_2_i;
    input fetch_enable_2_i; //enable cpu
    output irq_ack_2_o;
    input irq_2_i;
    input [4:0]irq_id_2_i;
    output [4:0]irq_id_2_o;
    output [31:0] eFPGA_operand_a_2_o;
    output [31:0] eFPGA_operand_b_2_o;
    input [31:0] eFPGA_result_a_2_i;
    input [31:0] eFPGA_result_b_2_i;
    input [31:0] eFPGA_result_c_2_i; //total 160 pins to fpga
    output eFPGA_write_strobe_2_o;  
    input eFPGA_fpga_done_2_i; 
    output eFPGA_en_2_o;
    output [1:0] eFPGA_operator_2_o;
    output [3:0] eFPGA_delay_2_o;

    wire [ADDR_WIDTH-1:0]ext_data_addr_i;
    wire [3:0]ext_data_be_i;
    wire [31:0]ext_data_rdata_o;
    wire ext_data_req_i;
    wire ext_data_rvalid_o;
    wire  [31:0]ext_data_wdata_i;
    wire ext_data_we_i;
    wire ext_data_gnt_o;

    input rxd_uart;
    output txd_uart;
    input rxd_uart_to_mem;
    output txd_uart_to_mem;
    output error_uart_to_mem;


    input wb_clk_i;
    input wb_rst_i;
    input wbs_stb_i;
    input wbs_cyc_i;
    input wbs_we_i;
    input [3:0] wbs_sel_i;
    input [31:0] wbs_dat_i;
    input [31:0] wbs_adr_i;
    output wbs_ack_o;
    output [31:0] wbs_dat_o;



    assign ext_data_addr_i = wbs_dat_i;
    assign ext_data_be_i = wbs_stb_i;
    assign wbs_dat_o = ext_data_rdata_o;
    assign ext_data_req_i = wbs_stb_i & wbs_cyc_i;
    assign wbs_ack_o = ext_data_rvalid_o;
    assign ext_data_wdata_i = wbs_dat_i;
    assign ext_data_we_i = wbs_we_i;


/*
    ram     ram_0
         (.clk(clk_i),
          .ibex_data_addr_i(flexbex_data_addr_o),
          .ibex_data_be_i(flexbex_data_be_o),
          .ibex_data_gnt_o(flexbex_data_gnt_i),
          .ibex_data_rdata_o(flexbex_data_rdata_o),
          .ibex_data_req_i(flexbex_data_req_o),
          .ibex_data_rvalid_o(flexbex_data_rvalid_o),
          .ibex_data_wdata_i(flexbex_data_wdata_o),
          .ibex_data_we_i(flexbex_data_we_o),

          .instr_addr_i(flexbex_instr_addr_o),
          .instr_gnt_o(flexbex_instr_gnt_o),
          .instr_rdata_o(flexbex_instr_rdata_o),
          .instr_req_i(flexbex_instr_req_o),
          .instr_rvalid_o(flexbex_instr_rvalid_o),
          
          .ext_data_addr_i(ext_data_addr_i),
          .ext_data_be_i(ext_data_be_i),
          .ext_data_rdata_o(ext_data_rdata_o),
          .ext_data_req_i(ext_data_req_i),
          .ext_data_rvalid_o(ext_data_rvalid_o),
          .ext_data_wdata_i(ext_data_wdata_o),
          .ext_data_we_i(ext_data_we_i));

*/

  wire reset_ni;
  assign reset_ni = ~reset;



    ibex_core ibex_core_1
        (.boot_addr_i(32'h0),
        .clk_i(clk_i),
        .cluster_id_i(6'd0),
        .core_id_i(4'd0),
        .data_addr_o(master_data_addr_to_inter[ (ADDR_WIDTH) - 1 : 0]),
        .data_be_o(master_data_be_to_inter[(  (DATA_WIDTH / 8)) - 1 : 0]),
        .data_err_i(1'b0),
        .data_gnt_i(master_data_gnt_to_inter[0]),
        .data_rdata_i(master_data_rdata_to_inter[ (DATA_WIDTH) - 1: 0 ]),
        .data_req_o(master_data_req_to_inter[0]),
        .data_rvalid_i(master_data_rvalid_to_inter[0]),
        .data_wdata_o(master_data_wdata_to_inter[ (DATA_WIDTH) - 1 : 0]),
        .data_we_o(master_data_we_to_inter[0]),
        .debug_req_i(debug_req_1_i),
        .ext_perf_counters_i(1'b0),
        .fetch_enable_i(fetch_enable_1_i),

        .instr_addr_o(master_data_addr_to_inter_ro[ ( ROMASTER_ADDR_WIDTH) - 1 : 0]),
        .instr_gnt_i(master_data_gnt_to_inter_ro[0]),
        .instr_rdata_i(master_data_rdata_to_inter_ro[ ( DATA_WIDTH) - 1: 0 ]),
        .instr_req_o(master_data_req_to_inter_ro[0]),
        .instr_rvalid_i(master_data_rvalid_to_inter_ro[0]),

        .irq_ack_o(irq_ack_1_o),
        .irq_i(irq_1_i),
        .irq_id_i(irq_id_1_i),
        .irq_id_o(irq_id_1_o),
        .rst_ni(reset_ni),
        .test_en_i(1'b1),
        .eFPGA_operand_a_o(eFPGA_operand_a_1_o),
        .eFPGA_operand_b_o(eFPGA_operand_b_1_o),
        .eFPGA_result_a_i(eFPGA_result_a_1_i),
        .eFPGA_result_b_i(eFPGA_result_b_1_i),
        .eFPGA_result_c_i(eFPGA_result_c_1_i),
        .eFPGA_write_strobe_o(eFPGA_write_strobe_1_o),
        .eFPGA_fpga_done_i(eFPGA_fpga_done_1_i),
        .eFPGA_en_o(eFPGA_en_1_o),
        .eFPGA_operator_o(eFPGA_operator_1_o),
        .eFPGA_delay_o(eFPGA_delay_1_o));







//need to set the debug vector
    ibex_core ibex_core_2
         (.boot_addr_i(32'h0),
          .clk_i(clk_i),
          .cluster_id_i(6'd0),
          .core_id_i(4'h1),
          
          .data_addr_o(master_data_addr_to_inter[ (2 * ADDR_WIDTH) - 1 : 1 * ADDR_WIDTH]),
          .data_be_o(master_data_be_to_inter[( (2 * (DATA_WIDTH / 8))) - 1 : 1 * (DATA_WIDTH / 8)]),
          .data_err_i(1'b0),
          .data_gnt_i(master_data_gnt_to_inter[1]),
          .data_rdata_i(master_data_rdata_to_inter[ (2 * DATA_WIDTH) - 1 : 1 * DATA_WIDTH]),
          .data_req_o(master_data_req_to_inter[1]),
          .data_rvalid_i(master_data_rvalid_to_inter[1]),
          .data_wdata_o(master_data_wdata_to_inter[ (2 * DATA_WIDTH) - 1 : 1 * DATA_WIDTH]),
          .data_we_o(master_data_we_to_inter[1]),

          .debug_req_i(debug_req_2_i),
          .ext_perf_counters_i(1'b0),
          .fetch_enable_i(fetch_enable_2_i),

        .instr_addr_o(master_data_addr_to_inter_ro[(2 * ROMASTER_ADDR_WIDTH) - 1 : ROMASTER_ADDR_WIDTH]),
        .instr_gnt_i(master_data_gnt_to_inter_ro[1]),
        .instr_rdata_i(master_data_rdata_to_inter_ro[(2 * DATA_WIDTH) - 1: DATA_WIDTH ]),
        .instr_req_o(master_data_req_to_inter_ro[1]),
        .instr_rvalid_i(master_data_rvalid_to_inter_ro[1]),


          .irq_ack_o(irq_ack_2_o),
          .irq_i(irq_2_i),
          .irq_id_i(irq_id_2_i),
          .irq_id_o(irq_id_2_o),
          .rst_ni(reset_ni),
          .test_en_i(1'b1),
          .eFPGA_operand_a_o(eFPGA_operand_a_2_o),
          .eFPGA_operand_b_o(eFPGA_operand_b_2_o),
          .eFPGA_result_a_i(eFPGA_result_a_2_i),
          .eFPGA_result_b_i(eFPGA_result_b_2_i),
          .eFPGA_result_c_i(eFPGA_result_c_2_i),
	      .eFPGA_write_strobe_o(eFPGA_write_strobe_2_o),
          .eFPGA_fpga_done_i(eFPGA_fpga_done_2_i),
          .eFPGA_en_o(eFPGA_en_2_o),
          .eFPGA_operator_o(eFPGA_operator_2_o),
          .eFPGA_delay_o(eFPGA_delay_2_o));


//5 master and 1 slave

 inter #(.DATA_WIDTH(DATA_WIDTH),
        .MASTERS(4),
        .SLAVES(3))
        inter_i(
        .clk(clk_i),
        .reset(reset),
        .master_data_req_i(master_data_req_to_inter),
        .master_data_addr_i(master_data_addr_to_inter),
        .master_data_we_i(master_data_we_to_inter),
        .master_data_be_i(master_data_be_to_inter),
        .master_data_wdata_i(master_data_wdata_to_inter),
        .master_data_rdata_o(master_data_rdata_to_inter),
        .master_data_rvalid_o(master_data_rvalid_to_inter),
        .master_data_gnt_o(master_data_gnt_to_inter),
        .slave_data_req_o(slave_data_req_to_inter),
        .slave_data_addr_o(slave_data_addr_to_inter),
        .slave_data_we_o(slave_data_we_to_inter),
        .slave_data_be_o(slave_data_be_to_inter),
        .slave_data_wdata_o(slave_data_wdata_to_inter),
        .slave_data_rdata_i(slave_data_rdata_to_inter),
        .slave_data_rvalid_i(slave_data_rvalid),
        .slave_data_gnt_i({ slave_data_gnt_peri1_i,2'd3})
);

 

    wire [MASTERS - 1:0] master_data_req_to_inter;
    wire [(MASTERS * ADDR_WIDTH) - 1:0] master_data_addr_to_inter;
    wire [MASTERS - 1:0] master_data_we_to_inter;
    wire [(MASTERS * (DATA_WIDTH / 8)) - 1:0] master_data_be_to_inter;
    wire [(MASTERS * DATA_WIDTH) - 1:0] master_data_wdata_to_inter;
    wire [(MASTERS * DATA_WIDTH) - 1:0] master_data_rdata_to_inter;
    wire [MASTERS - 1:0] master_data_rvalid_to_inter;
    wire [MASTERS - 1:0] master_data_gnt_to_inter;

    wire [SLAVES - 1:0] slave_data_req_to_inter;
    wire [(SLAVES * SLAVE_ADDR_WIDTH) - 1:0] slave_data_addr_to_inter;
    wire [SLAVES - 1:0] slave_data_we_to_inter;
    wire [(SLAVES * (DATA_WIDTH / 8) ) - 1:0] slave_data_be_to_inter;
    wire [(SLAVES * DATA_WIDTH) - 1:0] slave_data_wdata_to_inter;
    wire [(SLAVES * DATA_WIDTH) - 1:0] slave_data_rdata_to_inter;



    wire slave_data_rvalid_to_inter;
    wire slave_data_gnt_to_inter;

    assign master_data_addr_to_inter[ (3 * ADDR_WIDTH) - 1: 2 * ADDR_WIDTH ]  = ext_data_addr_i;
    assign master_data_be_to_inter[( (3 * (DATA_WIDTH / 8))) - 1 : 2 * (DATA_WIDTH / 8)] = ext_data_be_i;
    assign ext_data_rdata_o = master_data_rdata_to_inter[ (3 * DATA_WIDTH) - 1 : 2 * DATA_WIDTH];
    assign master_data_req_to_inter[2] = ext_data_req_i;
    assign ext_data_rvalid_o = master_data_rvalid_to_inter[2];
    assign master_data_wdata_to_inter[ (3 * DATA_WIDTH) - 1 : 2 * DATA_WIDTH] = ext_data_wdata_i;
    assign master_data_we_to_inter[2] = ext_data_we_i;
    assign ext_data_gnt_o = master_data_gnt_to_inter[2];


    wire [ROMASTERS - 1:0] master_data_req_to_inter_ro;
    wire [(ROMASTERS * ROMASTER_ADDR_WIDTH) - 1:0] master_data_addr_to_inter_ro;
    wire [(ROMASTERS * DATA_WIDTH) - 1:0] master_data_rdata_to_inter_ro;
    wire [ROMASTERS - 1:0] master_data_rvalid_to_inter_ro;
    wire [ROMASTERS - 1:0] master_data_gnt_to_inter_ro;



    wire [ROSLAVES - 1:0] slave_data_req_to_inter_ro;
    wire [(ROSLAVES * SLAVE_ADDR_WIDTH) - 1:0] slave_data_addr_to_inter_ro;
    wire [(ROSLAVES * DATA_WIDTH) - 1:0] slave_data_rdata_to_inter_ro;




inter_read inter_read_i
(
        .clk(clk_i),
        .reset(reset),
        .master_data_req_i(master_data_req_to_inter_ro),
        .master_data_addr_i(master_data_addr_to_inter_ro),
        .master_data_rdata_o(master_data_rdata_to_inter_ro),
        .master_data_rvalid_o(master_data_rvalid_to_inter_ro),
        .master_data_gnt_o(master_data_gnt_to_inter_ro),
        .slave_data_req_o(slave_data_req_to_inter_ro), //active low
        .slave_data_addr_o(slave_data_addr_to_inter_ro),
        .slave_data_rdata_i(slave_data_rdata_to_inter_ro),
        .slave_data_gnt_i(2'd3)
);


//sky130_sram_1kbyte_1rw1r_32x256_8 sram_1_i(
sky130_sram_1kbyte_1rw1r_32x256_8 sram_1_i(
// Port 0: RW
    .clk0(clk_i),
    .csb0(!slave_data_req_to_inter[0]),
    .web0(!slave_data_we_to_inter[0]),
    .wmask0(slave_data_be_to_inter[( ((DATA_WIDTH / 8))) - 1 :0]),
    .addr0(slave_data_addr_to_inter[ (SLAVE_ADDR_WIDTH) - 1 : 0]),
    .din0(slave_data_wdata_to_inter[ (DATA_WIDTH) - 1 : 0 ]),
    .dout0(slave_data_rdata_to_inter[ (DATA_WIDTH) - 1 : 0 ]),
// Port 1: R
    .clk1(clk_i),
    .csb1(!slave_data_req_to_inter_ro[0]),
    .addr1(slave_data_addr_to_inter_ro[(SLAVE_ADDR_WIDTH) - 1 : 0]),
    .dout1(slave_data_rdata_to_inter_ro[(DATA_WIDTH) - 1 : 0])

  );

wire slave_data_gnt_peri1_i;
wire [SLAVES - 1:0]  slave_data_rvalid;
reg [SLAVES - 1:0]  slave_data_rvalid_write;
reg [SLAVES - 1:0]  slave_data_rvalid_read;

assign slave_data_rvalid[0] = slave_data_rvalid_write[0] | slave_data_rvalid_read[0];
assign slave_data_rvalid[1] = slave_data_rvalid_write[1] | slave_data_rvalid_read[1];
assign slave_data_rvalid[2] = slave_data_rvalid_write[2] | slave_data_rvalid_read[2];



wire slave_data_rvalid_peri1_i;
wire [SLAVES - 1:0]slave_data_rvalid_source = {slave_data_rvalid_peri1_i, 2'd3};

//for sram interfaces rvalid should be high following gnt(1) + we_o(0) 
genvar i;

generate
    for (i = 0; i < SLAVES; i = i + 1) begin
        always @(posedge clk_i)
        begin
            if(reset == 1)
                slave_data_rvalid_read[i] = 0;
            else if(slave_data_req_to_inter[i] == 1'b1 && slave_data_we_to_inter[i] == 1'b0)
                slave_data_rvalid_read[i] = slave_data_rvalid_source[i];
            else
                slave_data_rvalid_read[i] = 0;
        end
    end
endgenerate
genvar j;
generate
    for (j = 0; j < SLAVES; j = j + 1) begin
        always @(posedge clk_i)
        begin
            if(reset == 1)
                slave_data_rvalid_write[j] = 0;
            else if(slave_data_req_to_inter[j] == 1'b1 && slave_data_we_to_inter[j] == 1'b1)
                slave_data_rvalid_write[j] = slave_data_rvalid_source[j];
            else
                slave_data_rvalid_write[j] = 0;
        end
    end
endgenerate




//use sram module name
//sky130_sram_1kbyte_1rw1r_32x256_8 sram_2_i(
sky130_sram_1kbyte_1rw1r_32x256_8 sram_2_i(
// Port 0: RW
    .clk0(clk_i),
    .csb0(!slave_data_req_to_inter[1]),
    .web0(!slave_data_we_to_inter[1]),
    .wmask0(slave_data_be_to_inter[( (2 * (DATA_WIDTH / 8))) - 1 : ((DATA_WIDTH / 8))]),
    .addr0(slave_data_addr_to_inter[ (2 * SLAVE_ADDR_WIDTH) - 1 : SLAVE_ADDR_WIDTH]),
    .din0(slave_data_wdata_to_inter[ (2 * DATA_WIDTH) - 1 : DATA_WIDTH ]),
    .dout0(slave_data_rdata_to_inter[ (2 * DATA_WIDTH) - 1 : DATA_WIDTH ]),
// Port 1: R
    .clk1(clk_i),
    .csb1(!slave_data_req_to_inter_ro[1]),
    .addr1(slave_data_addr_to_inter_ro[(2 * SLAVE_ADDR_WIDTH) - 1 : SLAVE_ADDR_WIDTH]),
    .dout1(slave_data_rdata_to_inter_ro[ (2 * DATA_WIDTH) - 1 : DATA_WIDTH ])
  );


peripheral #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(SLAVE_ADDR_WIDTH)
) peripheral1( 
    .clk(clk_i),
    .reset(reset),
    .slave_data_addr_i(slave_data_addr_to_inter[ (3 * SLAVE_ADDR_WIDTH) - 1 : 2 * SLAVE_ADDR_WIDTH]),
    .slave_data_we_i(slave_data_we_to_inter[2]),
    .slave_data_be_i(slave_data_be_to_inter[( (3 * (DATA_WIDTH / 8))) - 1 : 2 * ((DATA_WIDTH / 8))]),
    .slave_data_wdata_i(slave_data_wdata_to_inter[ (3 * DATA_WIDTH) - 1 : 2 * DATA_WIDTH ]),
    .slave_data_rdata_o(slave_data_rdata_to_inter[ (3 * DATA_WIDTH) - 1 : 2 * DATA_WIDTH ]),
    .slave_data_rvalid_o(slave_data_rvalid_peri1_i),
    .slave_data_gnt_o(slave_data_gnt_peri1_i),
    .data_req_i(slave_data_req_to_inter[2]),
    .rxd_uart(rxd_uart),
    .txd_uart(txd_uart)
);

 uart_to_mem #(
     .ADDR_WIDTH(ADDR_WIDTH)
 )uart_to_mem_i(
    .clk_i(clk_i), // The master clock for this module
    .rst_i(reset), // Synchronous reset.
    .rx_i(rxd_uart_to_mem), // Incoming serial line
    .tx_o(txd_uart_to_mem),  // Outgoing serial line
    .data_req_o(master_data_req_to_inter[3]),//Request ready, must stay high until data_gnt_i is high for one cycle
    .data_addr_o(master_data_addr_to_inter[ (4 * ADDR_WIDTH) - 1: 3 * ADDR_WIDTH ]),//Address
    .data_we_o(master_data_we_to_inter[3] ),//Write Enable, high for writes, low for reads. Sent together with data_req_o
    .data_be_o(master_data_be_to_inter[( (4 * (DATA_WIDTH / 8))) - 1 : 3 * (DATA_WIDTH / 8)]),//Byte Enable. Is set for the bytes to write/read, sent together with data_req_o
    .data_wdata_o(master_data_wdata_to_inter[ (4 * DATA_WIDTH) - 1 : 3 * DATA_WIDTH]),//Data to be written to memory, sent together with data_req_o
    .data_rdata_i(master_data_rdata_to_inter[ (4 * DATA_WIDTH) - 1: 3 * DATA_WIDTH ]),//Data read from memory
    .data_rvalid_i(master_data_rvalid_to_inter[3]),//data_rdata_is holds valid data when data_rvalid_i is high. This signal will be high for exactly one cycle per request.
    .data_gnt_i(master_data_gnt_to_inter[3]),//The other side accepted the request. data_addr_o may change in the next cycle
    .uart_error(error_uart_to_mem)
    );



endmodule

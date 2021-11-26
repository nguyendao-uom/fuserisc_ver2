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

module inter_read #(
        parameter DATA_WIDTH = 32,
        parameter ROMASTER_ADDR_WIDTH = 11,
        parameter SLAVE_ADDR_WIDTH = 10,
        parameter ROMASTERS = 2,
        parameter ROSLAVES = 2
)(
        clk,
        reset,
        master_data_req_i,
        master_data_addr_i,
        master_data_rdata_o,
        master_data_rvalid_o,
        master_data_gnt_o,
        slave_data_req_o,
        slave_data_addr_o,
        slave_data_rdata_i,
        slave_data_gnt_i
);

        input clk;
        input reset;
        input wire [ROMASTERS - 1:0] master_data_req_i;
        input wire [(ROMASTERS * ROMASTER_ADDR_WIDTH) - 1:0] master_data_addr_i;

        

        output reg [(ROMASTERS * DATA_WIDTH) - 1:0] master_data_rdata_o;
        output reg [ROMASTERS - 1:0] master_data_rvalid_o;
        output reg [ROMASTERS - 1:0] master_data_gnt_o;
        output reg [ROSLAVES - 1:0] slave_data_req_o;
        output reg [(ROSLAVES * SLAVE_ADDR_WIDTH) - 1:0] slave_data_addr_o;
        input wire [(ROSLAVES * DATA_WIDTH) - 1:0] slave_data_rdata_i;
        input wire [ROSLAVES - 1:0] slave_data_gnt_i;
        reg arb_to_master_grant [ROMASTERS - 1:0];
        wire arb_active;
        genvar i;
        //genvar j;
        logic [(ROSLAVES * ROMASTERS) - 1:0] arbiter_request;
        wire [(ROSLAVES * ROMASTERS) - 1:0] arbiter_grant;
       //parameter [$clog2(SLAVES):0] PARAM_SLAVE_ADDR = 2'b10;
      
                for (i = 0; i < ROSLAVES; i = i + 1)  
                always @(*)
                begin
                        integer j;
                        for (j = 0; j < ROMASTERS; j = j + 1)
                                arbiter_request[(i * ROMASTERS) + j] = (  master_data_addr_i[(j * ROMASTER_ADDR_WIDTH + (SLAVE_ADDR_WIDTH )) +: $clog2(ROSLAVES)]   == i )? master_data_req_i[j] : 0;
                end
                for (i = 0; i < ROMASTERS; i = i + 1)
                        begin : sv2v_autoblock_1
                           always @(*)begin
                                reg local_arb_grant;
                                local_arb_grant = 1'b0;
                                begin : sv2v_autoblock_2
                                        reg signed [31:0] j;
                                    
                                        for (j = 0; j < ROSLAVES; j = j + 1)
                                                local_arb_grant = local_arb_grant | arbiter_grant[(j * ROMASTERS) + i];
                                end
                                arb_to_master_grant[i] = local_arb_grant;
                           end
                        end

                        
        generate
                for (i = 0; i < ROSLAVES; i = i + 1) begin : generate_arbiters
                        arbiter #(.NUM_PORTS(ROMASTERS)) i_arb(
                                .clk(clk),
                                .rst(reset),
                                .request(arbiter_request[(i * ROMASTERS) + (ROMASTERS - 1)-:ROMASTERS]),
                                .grant(arbiter_grant[(i * ROMASTERS) + (ROMASTERS - 1)-:ROMASTERS]),
                                .active(arb_active)
                        );
                end
        endgenerate
        genvar a,t;
         
         generate
                 for ( a = 0; a < ROSLAVES; a = a + 1)
                        begin : slave_out1
                          
                                always @(*)
                                begin 
                                        
                                        slave_data_addr_o[a * SLAVE_ADDR_WIDTH+:SLAVE_ADDR_WIDTH] = 0;
                                      
                                        

                                        slave_data_req_o[a] = 0;
                                        integer t;
                                        for (t = 0; t < ROMASTERS; t = t + 1)
                                        begin : slave_out2
                                                
                                
                                                if (arbiter_grant[(a*ROMASTERS) + t] == 1'b1) begin : slave_out
                                                        slave_data_addr_o[a * SLAVE_ADDR_WIDTH+:SLAVE_ADDR_WIDTH] = master_data_addr_i[t * ROMASTER_ADDR_WIDTH+:ROMASTER_ADDR_WIDTH];

                                                        
                                                        
                                                        //need to fix
                                                        slave_data_req_o[a] = master_data_req_i[t];
                                                end
                                        end
                                end
                             

                        end
         endgenerate
        
        generate
        for (i = 0; i < ROMASTERS; i = i + 1)
                begin :m_data1
                        always @(*)                       
                        begin :m_data2
                                master_data_rdata_o[i * DATA_WIDTH+:DATA_WIDTH] = 0;
                                master_data_rvalid_o[i] = 0;
                                master_data_gnt_o[i] = 0;
                                integer k;
                                for (k = 0; k < ROSLAVES; k = k + 1)
                                begin
                                        if (arbiter_grant[(k * ROMASTERS) + i] == 1'b1) 
                                        begin 
                                                master_data_rdata_o[i * DATA_WIDTH+:DATA_WIDTH] = slave_data_rdata_i[k * DATA_WIDTH+:DATA_WIDTH];
                                                master_data_rvalid_o[i] = 1'b1;
                                                master_data_gnt_o[i] = slave_data_gnt_i[k] & master_data_req_i[i] ;
                                        end
                                end
                        end
                end
        endgenerate
endmodule

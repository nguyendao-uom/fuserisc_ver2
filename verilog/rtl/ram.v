module ram (
	clk,
	instr_req_i,
	instr_addr_i,
	instr_rdata_o,
	instr_rvalid_o,
	instr_gnt_o,
	ibex_data_req_i,
	ibex_data_addr_i,
	ibex_data_we_i,
	ibex_data_be_i,
	ibex_data_wdata_i,
	ibex_data_rdata_o,
	ibex_data_rvalid_o,
	ibex_data_gnt_o,
	ext_data_req_i,
	ext_data_addr_i,
	ext_data_we_i,
	ext_data_be_i,
	ext_data_wdata_i,
	ext_data_rdata_o,
	ext_data_rvalid_o
);
	parameter ADDR_WIDTH = 10;
	input wire clk;
	input wire instr_req_i;
	input wire [ADDR_WIDTH - 1:0] instr_addr_i;
	output wire [31:0] instr_rdata_o;
	output reg instr_rvalid_o;
	output wire instr_gnt_o;
	input wire ibex_data_req_i;
	input wire [ADDR_WIDTH - 1:0] ibex_data_addr_i;
	input wire ibex_data_we_i;
	input wire [3:0] ibex_data_be_i;
	input wire [31:0] ibex_data_wdata_i;
	output wire [31:0] ibex_data_rdata_o;
	output reg ibex_data_rvalid_o;
	output wire ibex_data_gnt_o;
	input wire ext_data_req_i;
	input wire [ADDR_WIDTH - 1:0] ext_data_addr_i;
	input wire ext_data_we_i;
	input wire [3:0] ext_data_be_i;
	input wire [31:0] ext_data_wdata_i;
	output wire [31:0] ext_data_rdata_o;
	output reg ext_data_rvalid_o;
	wire data_req_i;
	wire [ADDR_WIDTH - 1:0] data_addr_i;
	wire [31:0] data_wdata_i;
	wire [31:0] data_rdata_o;
	wire data_we_i;
	wire [3:0] data_be_i;
	assign data_req_i = (ext_data_req_i ? ext_data_req_i : ibex_data_req_i);
	assign data_addr_i = (ext_data_req_i ? ext_data_addr_i : ibex_data_addr_i);
	assign data_wdata_i = (ext_data_req_i ? ext_data_wdata_i : ibex_data_wdata_i);
	assign ext_data_rdata_o = data_rdata_o;
	assign ibex_data_rdata_o = data_rdata_o;
	assign data_we_i = (ext_data_req_i ? ext_data_we_i : ibex_data_we_i);
	assign data_be_i = (ext_data_req_i ? ext_data_be_i : ibex_data_be_i);
	assign ibex_data_gnt_o = !ext_data_req_i & ibex_data_req_i;
	sram_1rw1r_32_256_8_sky130 sram_i(
		.clk0(clk),
		.csb0(!data_req_i),
		.web0(!data_be_i),
		.wmask0(data_be_i),
		.addr0(data_addr_i),
		.din0(data_wdata_i),
		.dout0(data_rdata_o),
		.clk1(clk),
		.csb1(!instr_addr_i),
		.addr1(instr_addr_i),
		.dout1(instr_rdata_o)
	);
	assign instr_gnt_o = instr_req_i;
	always @(posedge clk) begin
		if (ext_data_req_i)
			ext_data_rvalid_o <= data_req_i;
		else
			ibex_data_rvalid_o <= data_req_i;
		instr_rvalid_o <= instr_req_i;
	end
endmodule

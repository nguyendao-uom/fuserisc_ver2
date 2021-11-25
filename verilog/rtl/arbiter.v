module arbiter (
	clk,
	rst,
	request,
	grant,
	select,
	active
);
	parameter NUM_PORTS = 5;
	parameter SEL_WIDTH = (NUM_PORTS > 1 ? $clog2(NUM_PORTS) : 1);
	input clk;
	input rst;
	input [NUM_PORTS - 1:0] request;
	output reg [NUM_PORTS - 1:0] grant;
	output reg [SEL_WIDTH - 1:0] select;
	output reg active;
	localparam WRAP_LENGTH = 2 * NUM_PORTS;
	function [SEL_WIDTH - 1:0] ff1;
		input [NUM_PORTS - 1:0] in;
		reg set;
		integer i;
		begin
			set = 1'b0;
			ff1 = 'b0;
			for (i = 0; i < NUM_PORTS; i = i + 1)
				if (in[i] & ~set) begin
					set = 1'b1;
					ff1 = i[0+:SEL_WIDTH];
				end
		end
	endfunction
	integer yy;
	wire next;
	wire [NUM_PORTS - 1:0] order;
	reg [NUM_PORTS - 1:0] token;
	wire [NUM_PORTS - 1:0] token_lookahead [NUM_PORTS - 1:0];
	wire [WRAP_LENGTH - 1:0] token_wrap;
	assign token_wrap = {token, token};
	assign next = ~|(token & request);
	always @(posedge clk) grant <= token & request;
	always @(posedge clk) select <= ff1(token & request);
	always @(posedge clk) active <= |(token & request);
	always @(posedge clk)
		if (rst)
			token <= 'b1;
		else if (next)
			for (yy = 0; yy < NUM_PORTS; yy = yy + 1)
				begin : TOKEN_
					if (order[yy])
						token <= token_lookahead[yy];
				end
	genvar xx;
	generate
		for (xx = 0; xx < NUM_PORTS; xx = xx + 1) begin : ORDER_
			assign token_lookahead[xx] = token_wrap[xx+:NUM_PORTS];
			assign order[xx] = |(token_lookahead[xx] & request);
		end
	endgenerate
endmodule

module ibex_multdiv_slow (
	clk,
	rst_n,
	mult_en_i,
	div_en_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero,
	alu_operand_a_o,
	alu_operand_b_o,
	multdiv_result_o,
	ready_o
);
	input wire clk;
	input wire rst_n;
	input wire mult_en_i;
	input wire div_en_i;
	input md_op_e operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	output reg [31:0] multdiv_result_o;
	output wire ready_o;
	reg [4:0] multdiv_state_q;
	reg [4:0] multdiv_state_d;
	wire [4:0] multdiv_state_m1;
	reg [2:0] curr_state_q;
	reg [2:0] curr_state_d;
	reg [32:0] accum_window_q;
	reg [32:0] accum_window_d;
	wire [32:0] res_adder_l;
	wire [32:0] res_adder_h;
	reg [32:0] op_b_shift_q;
	reg [32:0] op_b_shift_d;
	reg [32:0] op_a_shift_q;
	reg [32:0] op_a_shift_d;
	wire [32:0] op_a_ext;
	wire [32:0] op_b_ext;
	wire [32:0] one_shift;
	wire [32:0] op_a_bw_pp;
	wire [32:0] op_a_bw_last_pp;
	wire [31:0] b_0;
	wire sign_a;
	wire sign_b;
	wire [32:0] next_reminder;
	wire [32:0] next_quotient;
	wire [32:0] op_remainder;
	reg [31:0] op_numerator_q;
	reg [31:0] op_numerator_d;
	wire is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	assign res_adder_l = alu_adder_ext_i[32:0];
	assign res_adder_h = alu_adder_ext_i[33:1];
	localparam [2:0] MD_ABS_A = 1;
	localparam [2:0] MD_ABS_B = 2;
	localparam [2:0] MD_CHANGE_SIGN = 5;
	localparam [2:0] MD_IDLE = 0;
	localparam [2:0] MD_LAST = 4;
	always @(*) begin
		alu_operand_a_o = accum_window_q;
		multdiv_result_o = (div_en_i ? accum_window_q[31:0] : res_adder_l);
		case (operator_i)
			MD_OP_MULL: alu_operand_b_o = op_a_bw_pp;
			MD_OP_MULH: alu_operand_b_o = (curr_state_q == MD_LAST ? op_a_bw_last_pp : op_a_bw_pp);
			default:
				case (curr_state_q)
					MD_IDLE: begin
						alu_operand_a_o = 33'b000000000000000000000000000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					MD_ABS_A: begin
						alu_operand_a_o = 33'b000000000000000000000000000000001;
						alu_operand_b_o = {~op_a_i, 1'b1};
					end
					MD_ABS_B: begin
						alu_operand_a_o = 33'b000000000000000000000000000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					MD_CHANGE_SIGN: begin
						alu_operand_a_o = 33'b000000000000000000000000000000001;
						alu_operand_b_o = {~accum_window_q[31:0], 1'b1};
					end
					default: begin
						alu_operand_a_o = {accum_window_q[31:0], 1'b1};
						alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
					end
				endcase
		endcase
	end
	assign is_greater_equal = ((accum_window_q[31] ^ op_b_shift_q[31]) == 1'b0 ? res_adder_h[31] == 1'b0 : accum_window_q[31]);
	assign one_shift = 33'b000000000000000000000000000000001 << multdiv_state_q;
	assign next_reminder = (is_greater_equal ? res_adder_h : op_remainder);
	assign next_quotient = (is_greater_equal ? op_a_shift_q | one_shift : op_a_shift_q);
	assign b_0 = {32 {op_b_shift_q[0]}};
	assign op_a_bw_pp = {~(op_a_shift_q[32] & op_b_shift_q[0]), op_a_shift_q[31:0] & b_0};
	assign op_a_bw_last_pp = {op_a_shift_q[32] & op_b_shift_q[0], ~(op_a_shift_q[31:0] & b_0)};
	assign sign_a = op_a_i[31] & signed_mode_i[0];
	assign sign_b = op_b_i[31] & signed_mode_i[1];
	assign op_a_ext = {sign_a, op_a_i};
	assign op_b_ext = {sign_b, op_b_i};
	assign op_remainder = accum_window_q[32:0];
	assign multdiv_state_m1 = multdiv_state_q - 5'h01;
	assign div_change_sign = sign_a ^ sign_b;
	assign rem_change_sign = sign_a;
	always @(posedge clk or negedge rst_n) begin : proc_multdiv_state_q
		if (!rst_n) begin
			multdiv_state_q <= 5'h00;
			accum_window_q <= 33'h000000000;
			op_b_shift_q <= 33'h000000000;
			op_a_shift_q <= 33'h000000000;
			op_numerator_q <= 32'h00000000;
			curr_state_q <= MD_IDLE;
		end
		else begin
			multdiv_state_q <= multdiv_state_d;
			accum_window_q <= accum_window_d;
			op_b_shift_q <= op_b_shift_d;
			op_a_shift_q <= op_a_shift_d;
			op_numerator_q <= op_numerator_d;
			curr_state_q <= curr_state_d;
		end
	end
	localparam [2:0] MD_COMP = 3;
	localparam [2:0] MD_FINISH = 6;
	always @(*) begin
		multdiv_state_d = multdiv_state_q;
		accum_window_d = accum_window_q;
		op_b_shift_d = op_b_shift_q;
		op_a_shift_d = op_a_shift_q;
		op_numerator_d = op_numerator_q;
		curr_state_d = curr_state_q;
		if (mult_en_i || div_en_i)
			case (curr_state_q)
				MD_IDLE: begin
					case (operator_i)
						MD_OP_MULL: begin
							op_a_shift_d = op_a_ext << 1;
							accum_window_d = {~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:0] & {32 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							curr_state_d = MD_COMP;
						end
						MD_OP_MULH: begin
							op_a_shift_d = op_a_ext;
							accum_window_d = {1'b1, ~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:1] & {31 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							curr_state_d = MD_COMP;
						end
						MD_OP_DIV: begin
							accum_window_d = {33 {1'b1}};
							curr_state_d = (equal_to_zero ? MD_FINISH : MD_ABS_A);
						end
						default: begin
							accum_window_d = op_a_ext;
							curr_state_d = (equal_to_zero ? MD_FINISH : MD_ABS_A);
						end
					endcase
					multdiv_state_d = 5'd31;
				end
				MD_ABS_A: begin
					op_a_shift_d = {33 {1'sb0}};
					op_numerator_d = (sign_a ? alu_adder_i : op_a_i);
					curr_state_d = MD_ABS_B;
				end
				MD_ABS_B: begin
					accum_window_d = {32'h00000000, op_numerator_q[31]};
					op_b_shift_d = (sign_b ? alu_adder_i : op_b_i);
					curr_state_d = MD_COMP;
				end
				MD_COMP: begin
					multdiv_state_d = multdiv_state_m1;
					case (operator_i)
						MD_OP_MULL: begin
							accum_window_d = res_adder_l;
							op_a_shift_d = op_a_shift_q << 1;
							op_b_shift_d = op_b_shift_q >> 1;
						end
						MD_OP_MULH: begin
							accum_window_d = res_adder_h;
							op_a_shift_d = op_a_shift_q;
							op_b_shift_d = op_b_shift_q >> 1;
						end
						default: begin
							accum_window_d = {next_reminder[31:0], op_numerator_q[multdiv_state_m1]};
							op_a_shift_d = next_quotient;
						end
					endcase
					curr_state_d = (multdiv_state_q == 5'd1 ? MD_LAST : MD_COMP);
				end
				MD_LAST:
					case (operator_i)
						MD_OP_MULL: begin
							accum_window_d = res_adder_l;
							curr_state_d = MD_IDLE;
						end
						MD_OP_MULH: begin
							accum_window_d = res_adder_l;
							curr_state_d = MD_IDLE;
						end
						MD_OP_DIV: begin
							accum_window_d = next_quotient;
							curr_state_d = MD_CHANGE_SIGN;
						end
						default: begin
							accum_window_d = {1'b0, next_reminder[31:0]};
							curr_state_d = MD_CHANGE_SIGN;
						end
					endcase
				MD_CHANGE_SIGN: begin
					curr_state_d = MD_FINISH;
					case (operator_i)
						MD_OP_DIV: accum_window_d = (div_change_sign ? alu_adder_i : accum_window_q);
						default: accum_window_d = (rem_change_sign ? alu_adder_i : accum_window_q);
					endcase
				end
				MD_FINISH: curr_state_d = MD_IDLE;
				default:
					;
			endcase
	end
	assign ready_o = (curr_state_q == MD_FINISH) | ((curr_state_q == MD_LAST) & ((operator_i == MD_OP_MULL) | (operator_i == MD_OP_MULH)));
endmodule

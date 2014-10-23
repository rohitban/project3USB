module rc_nrzi
	(input  logic clk, rst_n,
	 
	 /* inputs from rc_dpdm */
	 input  logic s_in, 
	 input  logic start_rc_nrzi, end_rc_nrzi,

	 /* outputs to bit unstuffer */
	 output logic start_unstuffer, end_unstuffer,
	 output logic s_out
	 );

	logic sync_set;
	logic d;
	logic clr;

	assign d = ~(s_in ^ s_out);

	gen_dff 	rcdff(.clk, .rst_n, .d, .clr, 
									.q(s_out), .rd(1'b1),
									.sync_set);

	rc_nrzi_fsm 	rcnz_fsm(.*);

endmodule : rc_nrzi



module rc_nrzi_fsm
	(input  logic 	clk, rst_n,
	 input  logic   start_rc_nrzi, end_rc_nrzi,
	 output logic 	start_unstuffer, end_unstuffer,
	 output logic   sync_set);

	enum logic [1:0] {WAIT, READY, SEND, BUF} cs, ns;

	always_ff@(posedge clk, negedge rst_n)
		if(~rst_n)
			cs <= WAIT;
		else
			cs <= ns;

	always_comb begin
		start_unstuffer = 0;
		end_unstuffer = 0;
		sync_set = 0;
		case(cs)
			WAIT: 
			begin
				ns = (start_rc_nrzi)? READY : WAIT;
				sync_set = (start_rc_nrzi) ? 1'b1 : 1'b0;
			end
			READY: 
			begin
				ns = SEND;
				start_unstuffer = 1;
			end
			SEND:
			begin
				ns = (end_rc_nrzi)? BUF : SEND;
			end
			BUF: 
			begin
				ns = WAIT;
				end_unstuffer = 1;
			end
	 endcase
	end

endmodule : rc_nrzi_fsm

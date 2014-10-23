/* bitUnstuffer - the module does two things : 
	1. Checks if the PID is valid
		 If PID is not valid it will
		 		a. send PID_error signal to ProtocolFSM
				b. sends an end signal to other modules 
	2. If PID is valid, it Unstuffs the data and sends them to crc module
*/
module bitUnstuffer
	(input  logic  clk, rst_n,
	 
	 /* inputs from rc_nrzi */
	 input  logic  s_in,
	 input  logic  start_unstuffer, 
	 input  logic  end_unstuffer,

	 /* outputs to bit stream decoder */
	 output logic  s_out,
	 output logic  start_decode, 
	 output logic  end_decode
	 );

	logic incr_ones, incr_pid, clr_ones, clr_pid;
	logic [4:0] ones_count, pid_count;
	logic we, re, full, empty;


	/* FIFO */
	fifo      q(.clk, .rst_n, 
							.we, .re, 
							.bit_in(s_in), .bit_out(s_out),
							.full, .empty);
	
	/* ones counter */
	counter  #(5) ones(.clk, .rst_n, .en(incr_ones),
										.clr(clr_ones), .count(ones_count));

	/* pid counter */
	counter  #(5)   pid(.clk, .rst_n, .en(incr_pid), 
										.clr(clr_pid), .count(pid_count));
	
	/* FSM */
	bitUnstuffer_fsm  unstuff(.*);

endmodule : bitUnstuffer


module bitUnstuffer_fsm
	(input  logic  clk, rst_n,
	 /* inputs from rc_nrzi */
	 input  logic  s_in, 
	 input  logic  start_unstuffer,
	 							 end_unstuffer,
	 input  logic [4:0]  ones_count, pid_count,

	 /* outputs to bit stream decoder */
	 output logic  start_decode,
	 output logic  end_decode,

	 /* FIFO */
	 input  logic  empty,
	 output logic  re, we,

	 /* outputs to counters */
	 output logic  clr_pid, clr_ones,
	 output logic  incr_pid, incr_ones
	 );

	 enum logic [2:0] {WAIT, READY, UNSTUFF, DONE} cs, ns;

	 always_ff@(posedge clk, negedge rst_n)
	 	if(~rst_n)
			cs <= WAIT;
		else
			cs <= ns;

		always_comb begin
			start_decode = 0;
			end_decode = 0;
			/* FIFO */
			re = 0; we = 0;
			/* Counter */
			clr_pid = 0; clr_ones = 0;
			incr_pid = 0; incr_ones = 0;
			case(cs)
			WAIT: 
			begin
				ns = (start_unstuffer) ? READY : WAIT;
				we = (start_unstuffer) ? 1 : 0;
				incr_pid = (start_unstuffer) ? 1 : 0;
			end
			READY:
			begin
				if (pid_count <= 5'd8) 
					begin
					ns = READY;
					incr_pid = 1;
					we = 1;
					end
				else /* pid_count > 5'd8 */
					begin
					start_decode = 1;
					ns = (end_unstuffer) ? DONE : UNSTUFF;
					we = (end_unstuffer) ? 0 : 1;
					re = 1;
					incr_ones = (end_unstuffer) ? 0 : (s_in == 1'b1) ? 1 : 0;
					end
			end
			UNSTUFF:
			begin
				ns = (end_unstuffer) ? DONE : UNSTUFF;
				if(ones_count <= 5'd6)
					begin
					incr_ones = (s_in == 1) ? 1 : 0;
					clr_ones = (s_in == 0) ?  1 : 0;
					we = 1;
					re = 1;
					end
				else /* ones_count >= 5'd6 */
					begin
					clr_ones = 1;
					re = 1;
					end
			end
			DONE:
			begin
				if(empty) 
					begin
					ns = WAIT;
					clr_ones = 1;
					clr_pid = 1;
					end_decode = 1;
					re = 0;
					end
				else
					begin
					ns = DONE;
					re = 1;
					end
			end
		endcase
	end
endmodule : bitUnstuffer_fsm

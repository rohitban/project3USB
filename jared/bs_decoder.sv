`define DATA_SIZE 7'd80
`define HSHAKE_SIZE 5'd16

`define NONE 2'b00
`define DATA 2'b11
`define HSHAKE 2'b10

`define SYNC_IN 8'b0000_0001


module bs_decoder(
		input  logic 	clk, rst_n,

		/* inputs from bitUnstuffer */
		input  logic  start_decode, 
		input  logic  end_decode,
		input  logic  s_in,					

		/* outputs to rc_crc */
		output logic  s_out,
		output logic  start_rc_crc,
		output logic  end_rc_crc,

		/* outputs to protocolFSM */
		output logic  PID_error,
		/* inputs from protocolFSM */
		input  logic  rc_PIDerror
	);

	logic ld_h, ld_d, shft_h, shft_d;
	logic PID_checked, PID_valid, end_PID;

	pid_checker 				pid(.clk, .rst_n,
										 .start_decode, .end_PID, 
										 .s_in, .PID_checked, .PID_valid);
	
	decoderFSM					fsm(.*);

endmodule : bs_decoder


module decoderFSM
	(input  logic  clk, rst_n,
	 input  logic  s_in, 
	 /* inputs from bitUnstuffer */
	 input  logic  start_decode,
	 input  logic  end_decode,

	 /* outputs to rc_crc */
	 output logic  s_out,
	 output logic  start_rc_crc,
	 output logic  end_rc_crc,

	 /* inputs from protocolFSM */
	 input  logic  rc_PIDerror,
	 /*outputs to protocolFSM */
	 output logic  PID_error,

	 /* inputs from PID_checker */
	 input  logic  PID_checked,
	 input  logic  PID_valid,
	 /*outputs to PID_checker */
	 output logic  end_PID

	 );

	enum logic [1:0] {WAIT, LOAD, READY, ERROR} cs, ns;

	always_ff@(posedge clk, negedge rst_n)
		if(~rst_n)
			cs <= WAIT;
		else
			cs <= ns;
	
	always_comb begin
	PID_error = 0;
	end_PID = 0;
	start_rc_crc = 0;
	end_rc_crc = 0;
	case(cs)
	WAIT: 
	begin
		ns = (start_decode) ? LOAD : WAIT;
		start_rc_crc = (start_decode) ? 1 : 0;
		s_out = (start_decode) ? s_in : 1'bx;
	end
	LOAD: 
	begin
		if(end_decode)
			begin
			ns = READY;
			end_rc_crc = 1;
			end
		else 
			begin
			ns = LOAD;
			s_out = s_in;
			end
	end
	READY: 
	begin
		if(PID_checked & PID_valid)
			begin
			ns = WAIT;
			end_PID= 1;
			end
		else if(PID_checked & ~PID_valid)
			begin
			ns = ERROR;
			end_PID = 1;
			PID_error = 1;
			end
		else
			begin
			ns = READY;
			end
	end
	ERROR:
	begin
		ns = (rc_PIDerror) ? WAIT : ERROR;
		PID_error = (rc_PIDerror) ? 0 : 1;
	end
	endcase
	end

endmodule : decoderFSM


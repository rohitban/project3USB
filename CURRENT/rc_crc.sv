/* pkt_status */
`define RECEIVED 1'b1
`define PROCESSING 1'b0

/* PID CHECK */
`define NAK_PID_VAL 8'b01011010
`define ACK_PID_VAL 8'b01001011
`define DATA_PID_VAL 8'b11000011

module rc_crc
	(input  logic  clk, rst_n, abort,
	 
	 /* inputs from bit Unstuffer */
	 input  logic  s_in,
	 input  logic  start_rc_crc,
	 input  logic  end_rc_crc,

	 /* inputs from ProtocolFSM */
	 input  logic  rc_CRCerror, //error msg received
	 input  logic  pkt_rec,     //packet received

	 /* outputs to ProtocolFSM */
	 output logic  pkt_status,
	 output logic  CRC_error,
	 output logic  [7:0]  rc_hshake,
	 output logic  [63:0] rc_data,
	 output logic  rc_crc_wait
	 
	 );
	
	logic ld_pid, ld_d, shft_pid, shft_d, clr;
	logic crc16_out, crc16_done, crc16_ready, crc16_start, crc16_rec;
	logic ld_crc16, shft_crc16, crc_valid;
	logic [15:0] rc_crc16, crc16_val;
	logic incr;
	logic [6:0] count;

	sipo_register  #(8)    pid(.clk, .en(ld_pid), .left(shft_pid),
  								 	   .Q(rc_hshake), .s_in);
 
	sipo_register  #(64)  data(.clk, .en(ld_d), .left(shft_d),
									   .Q(rc_data), .s_in);

	rc_crc16						 crc_d(.clk, .rst_n, .crc16_val, 
										 	.crc16_ready, .crc16_done,
										 	.crc16_start, .crc16_rec,
										 	.crc16_out, .s_in);

	sipo_register  #(16)  crcval(.clk, .en(ld_crc16), .left(shft_crc16),
										  .Q(rc_crc16), .s_in);

	assign crc_valid = (crc16_val == rc_crc16);

	counter   #(7)   cnt(.clk, .rst_n, .count, .clr, .en(incr));

	rc_crc_fsm		  fsm(.*);

endmodule : rc_crc


module rc_crc_fsm
	(input  logic  clk, rst_n, abort,
	 input  logic  start_rc_crc, end_rc_crc,
	 /* inputs/outputs to protocolFSM */
	 input  logic  pkt_rec, rc_CRCerror,
	 output logic  pkt_status,
	 output logic  CRC_error,
	 output logic  rc_crc_wait,	 
	 /* inputs/outputs to counter */
	 input  logic  [6:0]  count,
	 output logic         clr, incr,

	 /* inputs/outputs to registers */
	 input  logic  [7:0]  rc_hshake,
	 output logic  ld_pid, ld_d, ld_crc16,
	 output logic  shft_pid, shft_d, shft_crc16,
	 
	 /* inputs/outputs to crc16 */
	 output logic  crc16_start, crc16_rec,
	 input  logic  crc16_done, crc_valid

	 );

	enum logic [2:0] {WAIT, GET_PID, HSHAKE_DONE, DATA_WAIT, 
							CRC_CHECK, ERROR} cs, ns;

	always_ff@(posedge clk, negedge rst_n)
		if(~rst_n)
			cs <= WAIT;
		else if(abort)
			cs <= WAIT;
		else
			cs <= ns;
	
	always_comb begin
		rc_crc_wait = 0;
		/* protocolFSM */
		pkt_status = `PROCESSING;
		CRC_error = 0;
		/* counter */
		clr = (abort) ? 1 : 0; 
		incr = 0;
		/* registers */
		ld_pid = 0; ld_d = 0; ld_crc16 = 0;
		shft_pid = 0; shft_d = 0; shft_crc16 = 0;
		/* crc16 */
		crc16_start = 0; crc16_rec = 0;
		case(cs)
		WAIT: 
		begin
			ns = (start_rc_crc) ? GET_PID : WAIT;
			incr = (start_rc_crc) ? 1 : 0;
			ld_pid = (start_rc_crc) ? 1 : 0;
			shft_pid = (start_rc_crc) ? 1 : 0;
			//rc_crc_wait = (start_rc_crc) ? 0 : 1;
			rc_crc_wait = 1;
		end
		GET_PID: 
		begin
			if(count <= 7'd8) 
				begin
					ns = GET_PID;
					incr = 1;
					ld_pid = 1;
					shft_pid = 1;
				end
			else if(count > 7'd8)
				begin
				if((rc_hshake == `NAK_PID_VAL) || (rc_hshake == `ACK_PID_VAL))
					begin
					ns = HSHAKE_DONE;
					pkt_status = `RECEIVED;
					end
				else if(rc_hshake == `DATA_PID_VAL)
					begin
					ns = DATA_WAIT;
				   incr = 1;
					ld_d = 1;
					shft_d = 1;
					crc16_start = 1;
					end
				else 
					begin
					ns = GET_PID;
					$display("PID VALUE IS WRONG!!! PID_CHECKED SHOULD BE 1, PID_VALID SHOULD BE 0!!");
					end
				end
		end
		HSHAKE_DONE:
		begin
			if(pkt_rec)
				begin
				ns = WAIT;
				clr = 1;
				end
			else
				begin
				ns = HSHAKE_DONE;
				pkt_status = `RECEIVED;
				end
		end
		DATA_WAIT:
		begin
			if(count <= 7'd72)
				begin
					//crc16_start = 1;
					ns = DATA_WAIT;
					incr = 1;
					ld_d = 1;
					shft_d = 1;
				end
			else 
				begin
					ns = CRC_CHECK;
					ld_crc16 = 1;
					shft_crc16 = 1;
				end
		end
		CRC_CHECK: 
		begin
			if(end_rc_crc)
				begin
				if(crc16_done && crc_valid)
					begin
					ns = HSHAKE_DONE;
					pkt_status = `RECEIVED;
					crc16_rec = 1;
					end
				else if(crc16_done && ~crc_valid)
					begin
					ns = ERROR;
					crc16_rec = 1;
					CRC_error = 1;
					end
				else if(~crc16_done)
					begin
					ns = CRC_CHECK;
					$display("BUG IN CRC_CHECK STATE!!!");
					end
				end
			else /* ~end_rc_crc */
				begin
				ns = CRC_CHECK;
				ld_crc16 = 1;
				shft_crc16 = 1;
				incr = 1;
				end
		end
		ERROR: 
		begin
			if(rc_CRCerror)
				begin
				ns = WAIT;
				clr = 1;
				end
			else
				begin
				ns = ERROR;
				CRC_error = 1;
				end
		end
		endcase
	end

endmodule : rc_crc_fsm


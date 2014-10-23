/* PID values */
`define NAK_PID 8'b01011010
`define ACK_PID 8'b01001011

/* outputs to bit stream encoder */
`define NONE 2'b00
`define TOKEN 2'b01
`define DATA 2'b11
`define HSHAKE 2'b10

/* inputs from read/write FSM */
`define IN_TOK 3'b001
`define OUT_TOK 3'b010
`define OUT_DATA 3'b011
`define IN_DATA 3'b100

/* constant Values */
`define IN_TOK_VAL 19'b1001_0110_10100000_001
`define OUT_TOK_VAL 19'b1000_0111_10100000_001

/* pkt_status values */
`define RECEIVED 1'b1
`define PROCESSING 1'b0



module protocolFSM
	(input  logic clk, rst_L,

	 /* inputs from read/write FSM*/
	 input  logic [2:0]  msg_type,
	 input  logic [63:0] protocol_din,
	 /* outputs to read/write FSM */
	 output logic        protocol_free,
	 output logic        timeout,
	 output logic [63:0] protocol_dout,

	 /* inputs from bit stream encoder */
	 input  logic 			free_inbound,
	 /* outputs to bit stream encoder */
	 output logic [1:0]  pkt_type,
	 output logic [18:0] token, 
	 output logic [71:0] data,
	 output logic [7:0]  hshake,

	 /* inputs from bit stream decoder */
	 input  logic 			pkt_status,
								 /*  RECEIVED   = 1'b1
									   PROCESSING = 1'b0 */
	 input  logic 			PID_error,
	 input  logic 			CRC_error,
	 input  logic [63:0] device_data,
	 input  logic [7:0]  device_hshake,

	 /* outputs to bit stream decoder */
	 output logic 			pkt_rec,  /* if an uncorrupted packet has been received */
	 output logic 			rc_CRCerror, /* received crc error */
	 output logic 			rc_PIDerror,  /* received PID error */

	 /* inputs from DPDM */
	 input  logic         sent_pkt,

	 /* inputs from rc_DPDM */
	 input  logic 			 got_sync,
	 input  logic 			 EOP_error,

	 /* outputs to rc_DPDM */
	 output logic 			 rc_EOPerror,
	 
	 /* outputs to rc_DPDM and rc_crc */
	 output logic 			 receive_data,
	 output logic 			 receive_hshake,
	 
	 output logic 			 abort,
	 input  logic 			 rc_dpdm_wait, rc_nrzi_wait, 
	 input  logic 			 bitUnstuff_wait, bs_decoder_wait,
	 input  logic 			 rc_crc_wait);

	 logic [63:0] data_in_tmp;
	 logic [63:0] device_data_tmp;
	 logic [8:0]  count;
 	 logic [3:0]  attempt;
	 logic pkt_error;
	 logic incr_attempt, incr_count;
	 logic clr_count, clr_attempt;
	 logic all_at_wait;

	enum logic [3:0] {WAIT, 
	 						 SENDING_TOK,
							 CHECK_ATTEMPTS,
							 SENDING_DATA, HSHAKE_LISTEN, HSHAKE_RECEIVING,
							 DATA_LISTEN, DATA_RECEIVING, 
							 SENDING_NAK, SENDING_ACK} cs,ns;

	 always_ff@(posedge clk, negedge rst_L)
	 	if(~rst_L)
			cs <= WAIT;
		else
			cs <= ns;
	
	assign all_at_wait = (rc_dpdm_wait & rc_nrzi_wait & 
								 bitUnstuff_wait & bs_decoder_wait & rc_crc_wait);


	logic ld_dataWrite, clr_dataWrite;

	counter 	#(4)   attmpt(.count(attempt), .clr(clr_attempt), .en(incr_attempt), 
								  .clk, .rst_n(rst_L));

	counter  #(9)   cnt(.count, .clr(clr_count), .en(incr_count), 
								 .clk, .rst_n(rst_L));

	register #(64)    din(.Q(data_in_tmp), .D(protocol_din), 
								 .ld(ld_dataWrite), .clr(clr_dataWrite), 
								 .rst_n(rst_L), .clk);
 
	 always_comb begin
		abort = 0;
		/* register */
		 ld_dataWrite = 0;
		 clr_dataWrite = 0;

	 	 /* counters */
		 incr_attempt = 0;
		 incr_count = 0;
		 clr_count = 0;
		 clr_attempt = 0;

		 /* handshake signals regarding error msgs */
		 rc_CRCerror = 0;
		 rc_PIDerror = 0;
		 rc_EOPerror = 0;
		 /* handshake signal regarding packet */
		 pkt_rec = 0;

		 /* outputs to read/write FSM */
	 	 protocol_free = 0;
		 timeout = 0;
		 
		 /* outputs to rc_dpdm and rc_crc */
		 receive_data = 0;
		 receive_hshake = 0;
		 pkt_type = `NONE;

		 case(cs)
		 WAIT : 
		 begin
		 		if(msg_type == `IN_TOK) 
					begin
			 		ns = SENDING_TOK;
					pkt_type = `TOKEN;
					token = `IN_TOK_VAL;
					end
				else if(msg_type == `OUT_TOK) 
			  	begin
					ns = SENDING_TOK;
					pkt_type = `TOKEN;
					token = `OUT_TOK_VAL;
					end
			 	else if(msg_type == `OUT_DATA) 
			 	 	begin
			   	ns = SENDING_DATA;
					ld_dataWrite = 1;
				 	//data_in_tmp = protocol_din;
					clr_attempt = 1;
					/* send data */
					data = data_in_tmp;
					pkt_type = `DATA;
				 	end
			 	else if(msg_type == `IN_DATA) 
			 	 	begin
			   	ns = DATA_LISTEN;
					receive_data = 1;
				 	clr_attempt = 1;
					clr_count = 1;
					end
			 	else 
			 		begin
			 	 	ns = WAIT;
			   	protocol_free = 1;
				 	end
		 	end

		 /* TOKEN TRANSACTION */
		 SENDING_TOK : 
		 begin
			  if(sent_pkt) 
					begin
					ns = WAIT;
					protocol_free = 1;
					end
				else
					ns = SENDING_TOK;
		 end


		/* READ TRANSACTION */
		DATA_LISTEN : 
		begin
			if(count > 9'd255)
				begin
				ns = SENDING_NAK;
				incr_attempt = 1;
				pkt_type = `HSHAKE;
				hshake = `NAK_PID;
				end
			else if(count <= 9'd255 & ~got_sync)
				begin
				ns = DATA_LISTEN;
				incr_count = 1;
				receive_data = 1;
				end
			else if(count <= 9'd255 & got_sync)
				begin
				ns = DATA_RECEIVING;
				receive_data = 1;
				end
		end
		DATA_RECEIVING : 
		begin
			if(pkt_status == `PROCESSING)
				begin
				if(EOP_error | PID_error | CRC_error)
					begin
					abort = 1;
					ns = SENDING_NAK;
					incr_attempt = 1;
					pkt_type = `HSHAKE;
					hshake = `NAK_PID;
					rc_PIDerror = (PID_error) ? 1 : 0;
					rc_CRCerror = (CRC_error) ? 1 : 0;
					rc_EOPerror = (EOP_error) ? 1 : 0;
					end
				else
					begin
					ns = DATA_RECEIVING;
					receive_data = 1;
					end
				end
			else /* pkt_status == `RECEIVED */
				begin
				ns = SENDING_ACK;
				pkt_type = `HSHAKE;
				hshake = `ACK_PID;
				protocol_dout = device_data;
				pkt_rec = 1;
				end
		end
		SENDING_NAK :
		begin
			if(sent_pkt & all_at_wait) 
				begin
				if(attempt > 8)
					begin
					ns = WAIT;
					timeout = 1;
					protocol_free = 1;
					end
				else /* attempt <= 8 */
					begin
					ns = DATA_LISTEN;
					clr_count = 1;
					receive_data = 1;
					end
				end
			else /* ~sent_pkt */
				begin
				abort = 1;
				ns = SENDING_NAK;
				end
		end
		SENDING_ACK :
		begin
			if(sent_pkt)
				begin
				ns = WAIT;
				protocol_free = 1;
				end
			else /* ~sent_pkt */
				begin
				ns = SENDING_ACK;
				pkt_rec = 1;
				end
		end


		 /* WRITE TRANSACTION */
		 SENDING_DATA : 
		 begin
		 		 if(attempt > 4'd8)
				 		begin
						ns = WAIT;
						timeout = 1;
						protocol_free = 1;
						end
				 else if(attempt <= 4'd8 && ~sent_pkt)
				 		begin
						ns = SENDING_DATA;
						end
				 else if(attempt <= 4'd8 && sent_pkt)
				 		begin
						ns = HSHAKE_LISTEN;
						receive_hshake = 1;
						clr_count = 1;
						end
		end
		HSHAKE_LISTEN :
		begin
				if(count > 9'd255)
					begin
					ns = CHECK_ATTEMPTS;
					incr_attempt = 1;
					end
				else if(count <= 9'd255 && ~got_sync)
					begin
					ns = HSHAKE_RECEIVING;
					incr_count = 1;
					receive_hshake = 1;
					end
				else if(count <= 9'd255 && got_sync)
					begin
					ns = HSHAKE_RECEIVING;
					receive_hshake = 1;
					end
		end
		HSHAKE_RECEIVING : 
		begin
				if(pkt_status == `PROCESSING)
				begin
					if(PID_error | CRC_error | EOP_error)
						begin
						abort = 1;
						ns = CHECK_ATTEMPTS;
						incr_attempt = 1;
						rc_EOPerror = (EOP_error) ? 1 : 0;
						rc_CRCerror = (CRC_error) ? 1 : 0;
						rc_PIDerror = (PID_error) ? 1 : 0;
						end
					else 
						begin
						ns = HSHAKE_RECEIVING;
						receive_hshake = 1;
						end
				end
				else if(pkt_status == `RECEIVED)
				begin
					if(device_hshake == `NAK_PID)
						begin
						ns = CHECK_ATTEMPTS;
						incr_attempt = 1;
						pkt_rec = 1;
						end
					else if(device_hshake == `ACK_PID)
						begin
						ns = WAIT;
						protocol_free = 1;
						pkt_rec = 1;
						clr_dataWrite = 1;
						end
					else /* IT SHOULD NEVER ENTER HERE */
						begin
						$display("Bug(s) in HSHAKE_RECEIVING");
						ns = CHECK_ATTEMPTS;
						incr_attempt = 1;
						end
				end
		end
		CHECK_ATTEMPTS :
		begin
			pkt_rec = 1;
			if(attempt > 4'd8)
				begin
				ns = WAIT;
				timeout = 1;
				protocol_free = 1;
				clr_dataWrite = 1;
				end
			else /* attempt <= 4'd8 */
				begin
				if(all_at_wait)
					begin
					ns = SENDING_DATA;
					pkt_type = `DATA;
					data = data_in_tmp;
					end
				else	
					begin
					abort = 1;
					ns = CHECK_ATTEMPTS;
					end
				end
		end
	 endcase
	end

endmodule : protocolFSM

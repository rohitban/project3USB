
`define DATA_SIZE 7'd80
`define TOKEN_SIZE 6'd27
`define HSHAKE_SIZE 5'd16 

`define DATA 2'b11
`define TOKEN 2'b01
`define HSHAKE 2'b10

`define SYNC_IN 8'b0000_0001

module bs_encoder(
		input  logic        clk, rst_n,

	  /* inputs from ProtocolFSM */
		input  logic [1:0]  pkt_type,
	    /* 00 - no packet
	     * 01 - data
		   * 10 - token
		   * 11 - handshake */

		input  logic [71:0] data,   /* Data type */
		input  logic [18:0] token,  /* Token type */
		input  logic [7:0]  hshake, /* Handshake type */

		/* outputs to ProtocolFSM */
		//output logic        pkt_sent, 
		output logic 			  pkt_sent,
		output logic        free_inbound, /* ready to receive */
			
		/* inputs from dpdm */
		input  logic 				sent_pkt,

		/* outputs to crc*/
    output logic [1:0]  pkt_in,
		output logic        endr, /* start/end crc*/
		output logic        s_out /* serial out */
		);
		
		logic [1:0] sel;
		logic [6:0] count;
		logic 			clr, ld_d, ld_t, ld_h;
		logic				d_shft, t_shft, h_shft;

		assign pkt_sent = sent_pkt;

		/* data piso */
		piso_register  #(`DATA_SIZE,0)  dpiso(.clk, .rst_n, .clr,.ld(ld_d), 
                                              .left(d_shft),.s_out(d_out), 
                                              .D({`SYNC_IN,data}), .Q());

		/* token piso */
		piso_register  #(`TOKEN_SIZE,0)  tpiso(.clk, .rst_n, .clr,.ld(ld_t),
                                               .left(t_shft),.s_out(t_out), 
                                               .D({`SYNC_IN,token}), .Q());

		/* handshake piso */
		piso_register  #(`HSHAKE_SIZE,0)   hpiso(.clk, .rst_n, .clr,.ld(ld_h), 
                                                 .left(h_shft),.s_out(h_out), 
                                                 .D({`SYNC_IN,hshake}), .Q());

		/* counts the number of bits of data/token/handshake */
		counter  #(7)  bcount(.clk, .rst_n, .clr,.en(incr), .count);

		/* choose the bit to output */
		bsMux  			   sout(.Y(s_out), .sel,
													.data(d_out), 
													.token(t_out), 
													.hshake(h_out));

		BSfsm						 fsm(.*);
												 


endmodule: bs_encoder


module BSfsm(
	input  logic clk, rst_n,

/* ProtocolFSM */
	/* inputs from ProtocolFSM */
	input  logic [1:0] pkt_type,
	/* outputs to ProtocolFSM */
	output logic       free_inbound,


/* bitStuff */
	/* outputs to bitstuff */
    output logic [1:0] pkt_in,
	output logic endr,


/* dpdm */
	/* inputs from dpdm */
	input  logic       sent_pkt,


/* DataPath */
	/* inputs from counter */
	input  logic [6:0] count,
	/* ouputs to counter */
	output logic incr,
	output logic clr,

	/* outputs to piso */
	output logic d_shft, t_shft, h_shft,
	output logic ld_d, ld_t, ld_h,
	/* outputs to mux */
	output logic [1:0] sel
	);


  enum {WAIT, 
				HS0, HS1, HS_WAIT, 
				TOK0, TOK1, TOK_WAIT, 
				DATA0, DATA1, DATA_WAIT} 
				cs,ns;
	
	always_ff@(posedge clk, negedge rst_n) 
		if(~rst_n) 
			cs <= WAIT;
		else
			cs <= ns;
	

	always_comb begin
	    sel = 2'b0;
		d_shft = 0; t_shft = 0; h_shft = 0;
		clr = 0;
		incr = 0;
		pkt_in = 0;
        endr = 0;
		free_inbound = 0;
		ld_h = 0; ld_t = 0; ld_d = 0;
		case(cs)
			
			/* WAIT state */
			WAIT : begin
				if(pkt_type == `HSHAKE) begin
					ns = HS0;
					ld_h = 1;
					free_inbound = 0;
				//	pkt_received = 1;
				end
				else if(pkt_type == `TOKEN) begin
					ns = TOK0;
					ld_t = 1;
					free_inbound = 0;
			//		pkt_received = 1;
				end
				else if(pkt_type == `DATA) begin
					ns = DATA0;
					ld_d = 1;
					free_inbound = 0;
			//		pkt_received = 1;
				end
				else begin
					ns = WAIT;
					free_inbound = 1;
				end
			end

			/* HANDSHAKE states */
			HS0 : begin
				ns = HS1;
				pkt_in = `HSHAKE;
			end
			HS1 : begin
				sel = `HSHAKE; /* choose handshake */
				if(count >= `HSHAKE_SIZE) begin
					ns = HS_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < `HSHAKE_SIZE) begin
					ns = HS1;
					incr = 1;
					h_shft = 1;
				end
			end
			HS_WAIT : begin
				if(sent_pkt) begin
					ns = WAIT;
					free_inbound = 1;
				end
				else begin
					ns = HS_WAIT;
					endr = 1;
				end
			end

			/* TOKEN states */
			TOK0 : begin
				ns = TOK1;
				pkt_in = `TOKEN;
			end
			TOK1 : begin
				sel = `TOKEN; /* choose token */
				if(count >= `TOKEN_SIZE) begin
					ns = TOK_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < `TOKEN_SIZE) begin
					ns = TOK1;
					incr = 1;
					t_shft = 1;
				end
			end
			TOK_WAIT : begin
				if(sent_pkt) begin
					ns = WAIT;
					free_inbound = 1;
				end
				else begin 
					ns = TOK_WAIT;
					endr = 1;
				end
			end

			/* DATA states */
			DATA0 : begin
				ns = DATA1;
				pkt_in = `DATA;
			end
			DATA1 : begin
				sel = `DATA; /* choose data */
				if(count >= `DATA_SIZE) begin
					ns = DATA_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < `DATA_SIZE) begin
					ns = DATA1;
					incr = 1;
					d_shft = 1;
				end
			end
			DATA_WAIT : begin
				if(sent_pkt) begin
					ns = WAIT;
					free_inbound = 1;
				end
				else begin 
					ns = DATA_WAIT;
					endr = 1;
				end
			end
		endcase

	end

endmodule : BSfsm 

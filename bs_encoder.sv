'define DATA_SIZE 6'd96
'define TOKEN_SIZE 5'd32
'define HSHAKE_SIZE 4'd16 

'define DATA 2'b0
'define TOKEN 2'b1
'define HSHAKE 2'b10

'define SYNC 8'b0000_0001

module bs_encoder(
		input  logic        clk, rst_n,

	 /* inputs from ProtocolFSM */
		input  logic [1:0]  pkt_type,
	 /* 00 - no packet
	  * 01 - data
		* 10 - token
		* 11 - handshaek */
		input  logic [87:0] data,   /* Data type */
		input  logic [23:0] token,  /* Token type */
		input  logic [7:0]  hshake, /* Handshake type */
		/* outputs to ProtocolFSM */
		output logic        pkt_received, 
		output logic        free_inbound, /* ready to receive */
			
		/* inputs from dpdm */
		input  logic 				sent_pkt,

		/* input from bit stuff */
		input  logic        pause,   /* pause bit streaming */
		/* outputs to bitstuff */
		output logic        start, endr, /* start/end bitstuffing */
		output logic        s_out        /* serial out */
		);
		
		logic [1:0] sel;
		logic [6:0] count;
		logic 			clr, ld_d, ld_t, ld_h;
		logic				d_shft, t_shft, h_shft;

	

		/* data piso */
		piso_register  #('DATA_SIZE,0)  dpiso(.clk, .rst_n, clr,
														  	          .ld(ld_d), left(d_shft),
														 		          .s_out(d_out), .D({'SYNC,data}), .Q());

		/* token piso */
		piso_register  #('TOKEN_SIZE,0)  tpiso(.clk, .rst_n, clr,
																           .ld(ld_t), left(t_shft),
																           .s_out(t_out), .D({'SYNC,token}), .Q());

		/* handshake piso */
		piso_register  #('HSHAKE_SIZE,0)   hpiso(.clk, .rst_n, clr,
																  					 .ld(ld_h), left(h_shft),
																  					 .s_out(h_out), .D({'SYNC,hshake}), .Q());

		/* counts the number of bits of data/token/handshake */
		counter  #(7)  bcount(.clk, .rst_n, .clr,
		 											.en(incr), 
													.count);

		/* choose the bit to output */
		mux3to1  			   sout(.Y(s_out), .sel,
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
	output logic       pkt_recieved,


/* bitStuff */
	/* inputs from bitstuff */
	input  logic pause,
	/* outputs to bitstuff */
	output logic start, endr,


/* dpdm */
	/* inputs from dpdm */
	input  logic       sent_pkt,


/* DataPath */
	/* inputs from counter */
	input  logic count,
	/* ouputs to counter */
	output logic incr,
	output logic clr,

	/* outputs to piso */
	output logic d_shft, t_shft, h_shft,
	output logic ld_d, ld_t, ld_h,
	/* outputs to mux */
	output logic [1:0] sel,
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
		start = 0; endr = 0;
		free_inbound = 0;
		ld_h = 0; ld_t = 0; ld_d = 0;
		case(cs)
			
			/* WAIT state */
			WAIT : begin
				if(pkt_type == 'HSHAKE) begin
					ns = HS0;
					ld_h = 1;
					free_inbound = 0;
				end
				else if(pkt_type == 'TOKEN) begin
					ns = TOK0;
					ld_t = 1;
					free_inbound = 0;
				end
				else if(pkt_type == 'DATA) begin
					ns = DATA0;
					ld_d = 1;
					free_inbound = 0;
				end
				else begin
					ns = WAIT;
					free_inbound = 1;
				end
			end

			/* HANDSHAKE states */
			HS0 : begin
				ns = HS1;
				start = 1;
			end
			HS1 : begin
				sel = 2'b11; /* choose handshake */
				if(count >= 'HSHAKE_SIZE) begin
					ns = HS_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < 'HSHAKE_SIZE && pause == 1'b0) begin
					ns = HS1;
					incr = 1;
					h_shft = 1;
				end
				else begin
					ns = HS1;
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
				start = 1;
			end
			TOK1 : begin
				sel = 2'b01; /* choose token */
				if(count >= 'TOKEN_SIZE) begin
					ns = TOK_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < 'TOKEN_SIZE && pause == 1'b0) begin
					ns = TOK1;
					incr = 1;
					t_shft = 1;
				end
				else begin
					ns = TOK1;
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
				start = 1;
			end
			DATA1 : begin
				sel = 2'b0; /* choose data */
				if(count >= 'DATA_SIZE) begin
					ns = DATA_WAIT;
					clr = 1;
					endr = 1;
				end
				else if(count < 'DATA_SIZE && pause == 1'b0) begin
					ns = DATA1;
					incr = 1;
					t_shft = 1;
				end
				else begin
					ns = DATA1;
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



`define TOKEN 2'b01
`define DATA 2'b11
`define HSHAKE 2'b10

`define SYNC_IN 8'b0000_0001

`define DATA_SIZE 7'd80
`define TOKEN_SIZE 6'd27
`define HSHAKE_SIZE 5'd16 

/* num of clock cycles to get residue from complmeneted remainder */ 
`define DELAY_T 6'd15  


///////////////////////////////////////
////////           LIB            /////
///////////////////////////////////////


module sipo_register
  #(parameter w = 3)
  (output logic [w-1:0] Q,
   input  logic         clk,en,left,
   input  logic         s_in);
   
   always_ff @(posedge clk)
   if (en)begin
     if (left)
       Q <= (Q << 1) | s_in;
     else
       Q <= (Q >> 1) | (s_in << w-1);
   end

endmodule: sipo_register



module gen_dff
    #(parameter FFID = 0)
    (input  logic d, clk, rst_n, sync_set,rd,
     output logic q);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          q <= 0;
        else
          if(sync_set)
            q <= 1;
          else if(rd)
            q <= d;

endmodule: gen_dff

module piso_register
    #(parameter w = 3, def = 0)
    (output logic [w-1:0] Q,
     output logic         s_out,
     input  logic         ld,clr,left,
     input  logic         clk, rst_n,
     input  logic [w-1:0] D);

     assign s_out = Q[w-1];
     
     always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
          Q <= def;
        else if(clr)
          Q <= def;
        else if (ld)
          Q <= D;
        else if(left)
          Q <= ((Q << 1) & -2);//fill lowest bit with 0s
        
endmodule: piso_register

module counter
    #(parameter WIDTH = 4)
    (output logic [WIDTH-1:0] count,
     input  logic             clr,en,clk,rst_n);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          count <= 0;
        else if(clr)
          count <= 0;
        else if(en)
          count <= count+1;

endmodule: counter

module register
    #(parameter WIDTH = 8)
   (output logic [WIDTH-1:0] Q,
     input  logic [WIDTH-1:0] D,
     input  logic             ld,clr,
     input  logic             rst_n,clk);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          Q <= 0;
        else
          if(clr)
            Q <= 0;
          else if(ld)
            Q <= D;

endmodule: register

module mux2to1
    #(parameter w = 1)
    (output logic [w-1:0] Y,
     input  logic [w-1:0] I0,I1,
     input  logic sel);

    assign Y = (sel)?I1:I0;

endmodule: mux2to1

module bsMux
    (output logic Y,
     input  logic data,token,hshake,
     input  logic [1:0] sel);

    always_comb 
        case(sel)
            `DATA  :Y = data;
            `HSHAKE:Y = hshake;
            default:Y = token;
        endcase

    
endmodule: bsMux

module fifo
  (input  logic        clk, rst_n,
   input  logic        we, re,
   input  logic        bit_in,
   output logic        full, empty,
   output logic        bit_out);
	
  logic [5:0] count;
  bit [31:0] Q;
  logic [4:0]  putPtr, getPtr; //pointers wrap

  assign empty = (count == 0),
         full  = (count == 6'd32),
         bit_out = Q[getPtr];

  //always_ff@(posedge clk, negedge rst_b)
  always_ff@(posedge clk, negedge rst_n)
  begin
    if (~rst_n) begin
      count <= 0;
      getPtr <= 0;
      putPtr <= 0;
    end
    else begin
      if(we & re & (!full) & (!empty)) begin
        Q[putPtr] <= bit_in;
        putPtr <= putPtr + 1;
        getPtr <= getPtr + 1;
      end
      else if(we & (!full)) begin
        Q[putPtr] <= bit_in;
        putPtr <= putPtr + 1;
        count <= count + 1;
      end
      else if(re & (!empty)) begin
        getPtr <= getPtr + 1;
        count <= count - 1;
      end
    end
  end

endmodule : fifo


///////////////////////////////////////

///////////////////////////////////////
/////        CRC 5                /////
///////////////////////////////////////

module crc5_fsm
    (output logic [4:0] sync_set, rd,
     output logic       clr, comp_ld, comp_shift,
     output logic       clr_cnt,en, 
     output logic       crc5_ready, crc5_done,
     input  logic [4:0] crc_cnt,
     input  logic       crc5_start,crc5_rec,
     input  logic       clk, rst_n);
    enum logic [2:0] {INIT,ADDR,STREAM,BUFFER} cs, ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= INIT;
        else
          cs <= ns;

    always_comb begin
       sync_set = 5'b0;
       rd = 5'b11111;
       clr = 0;
       comp_ld = 0;
       comp_shift = 0;
       clr_cnt = 0;
       en = 0;
       crc5_ready = 0;
       crc5_done = 0;
       case(cs)
         INIT:begin
            ns = (crc5_start)?ADDR:INIT;
            sync_set = (crc5_start)?5'b11111:0;
         end
         ADDR:begin
            ns = (crc_cnt < 11)?ADDR:STREAM;
            rd = (crc_cnt < 11)?5'b11111:0;
            en  = (crc_cnt < 11)?1:0;
            clr_cnt = (crc_cnt < 11)?0:1;
            comp_ld = (crc_cnt < 11)?0:1;
         end
         STREAM : begin
            if(crc_cnt < 5)begin
			  ns = STREAM;
              comp_shift = 1;
              en = 1;
              crc5_ready = 1;
            end
			else
              ns = BUFFER;
         end	 
         BUFFER: begin
            ns = (crc5_rec)?INIT:BUFFER;
            clr = (crc5_rec)?1:0;
            clr_cnt = (crc5_rec)?1:0;
            crc5_done = 1;
         end
         
       endcase
    end

endmodule: crc5_fsm

module crc5
    (output logic       crc5_out,
     output logic       crc5_ready,crc5_done,
     input  logic       crc5_start, s_in,crc5_rec,
     input  logic       clk, rst_n);

    //DFF signals
    logic [4:0] dff_in, dff_out;
    logic [4:0] sync_set, rd;
   

    //Generator complement signals
    logic  [4:0] comp_out;
    logic        comp_serial;
    logic        clr, comp_ld, comp_shift;


    //GEN COMPLEMENT register
    piso_register #(5,0) comp_piso(.clk,.rst_n,.D(~dff_out),.Q(comp_out),
                                   .clr,.ld(comp_ld),
                                   .left(comp_shift),.s_out(crc5_out));

    //Counter
    logic clr_cnt, en;
    logic [4:0] crc_cnt;

    counter #(5) crc_count(.clk,.rst_n,.count(crc_cnt),.clr(clr_cnt),.en);


   //CRC FFs
   assign dff_in[0] = dff_out[4]^s_in,
          dff_in[1] = dff_out[0],
          dff_in[2] = dff_out[1]^(s_in^dff_out[4]),
          dff_in[4:3] = dff_out[3:2];

   genvar i;
   generate
    for(i = 0; i < 5; i = i+1) 

      gen_dff #(i) gen_ff_inst(.clk,.rst_n,.sync_set(sync_set[i]),
                               .d(dff_in[i]),.q(dff_out[i]),.rd(rd[i]));

   endgenerate

   crc5_fsm fsm_inst(.*);

endmodule: crc5

///////////////////////////////////////

//////////////////////////////////////
////       MASTER CRC MODULE      ////
//////////////////////////////////////

module crc(
	input  logic clk, rst_n,
	
	/* inputs from Bit Stream Encorder */
	input  logic 				s_in,
	input  logic 				endr,
	input  logic [1:0]          pkt_in,
	
	/* inputs from Bit Stuffer */
	input  logic        pause,
	/* ouputs to Bit Stuffer */
	output logic        start_b, endb,
	output logic				s_out
	);

    
    /*Main CRC*/
	logic crc_out;
    logic sel_16;
    logic sel_crc;

    /*CRC5*/
    logic crc5_out;
    logic crc5_ready, crc5_done;
    logic crc5_start, crc5_rec;

    /*CRC16
	logic crc16_out;
	logic crc16_ready, crc16_done; 
    logic crc16_start, crc16_rec;*/

    /*Queue signals*/
	logic re, we;
	logic full, empty;
	logic bit_in;

    /*Delay counter*/
	logic incr, clr;
	logic [5:0] delay_count;

	crc5			tcrc(.clk, .rst_n, 
								 .s_in,
								 .crc5_start, .crc5_ready, .crc5_done,
								 .crc5_out, .crc5_rec);
	//crc16			dcrc(.*);

	fifo					q(.clk, .rst_n,
									.we, .re,
									.bit_in, .bit_out(s_out),
									.full, .empty);

	counter #(6)  delay(.clk, .rst_n,
											.clr, .en(incr),
											.count(delay_count));


	mux2to1 			 qmux(.Y(bit_in), 
										  .I0(s_in),.I1(crc5_out),
                                          /*.I1(crc_out),*/
										  .sel(sel_crc));

	/*mux2to1				cmux(.Y(crc_out), 
										 .I0(crc5_out), .I1(crc16_out),
										 .sel(sel_16));*/
    crc_master_fsm      ctrl(.*);

endmodule : crc

module crc_master_fsm
    (
    //Queue control
    output logic re, we,
    //Queue status
	input logic empty,

    //MUX control
    //output logic sel_16,
    output logic sel_crc,

    //Counter control
    output logic clr, incr,
    //Counter status
    input  logic [5:0] delay_count,

    //CRC5 control
    output logic crc5_start, crc5_rec,
    //CRC5 status
    input logic crc5_ready, crc5_done,

    /*
    //CRC16 status
   	input logic crc16_ready, crc16_done; 
    //CRC16 control
    output logic crc16_start, crc16_rec;*/

    //Inputs from bs_encoder i.e. the crc god
    input logic [1:0] pkt_in,
    input logic       endr,

    //Outputs to the bit-stuffer a.k.a crc's bitch
    output logic start_b,endb,

    //Inputs from the bit-stuffer
    input  logic pause,
    
    input logic clk, rst_n);

   
    enum logic [3:0] {WAIT,TOK0,TOK1,TOK2,TOK3} crc_cs,crc_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          crc_cs <= WAIT;
        else
          crc_cs <= crc_ns;

    always_comb begin
        re = 0;
        we = 0;
        sel_crc = 0;
        //sel_16 = 0;
        clr = 0;
        incr = 0;
        crc5_start = 0;
        crc5_rec = 0;
        start_b = 0;
        endb = 0;

        case(crc_cs)
            WAIT:begin
                case(pkt_in)
                    `TOKEN: crc_ns = TOK0;
                    //`DATA: crc_ns = DATA0;
                    //`HSHAKE: crc_ns = HS0;
                    default: crc_ns = WAIT;
                endcase
            end
            TOK0: begin
                if(delay_count < `DELAY_T) begin
                  crc_ns = TOK0;
                  we = 1;
                  incr = 1;
                end
                else begin
                  crc_ns = TOK1;
                  we = 1;
                  crc5_start = 1;
                  clr = 1;
                  start_b = 1;
                end
            end
            TOK1: begin
                re = 1;
                if(endr) begin
                  crc_ns = TOK2;
                  //start_b = 1;
                end
                else begin
                  crc_ns = TOK1;
                  we = 1;
                end
            end
            TOK2: begin
              crc_ns = (crc5_done)?TOK3:TOK2;
              re = (pause)?1'b0:1'b1;
              we = (crc5_ready)?1'b1:1'b0;
              sel_crc = 1;
              crc5_rec = (crc5_done)?1'b1:1'b0;
            end
            TOK3: begin
               crc_ns = (empty)?WAIT:TOK3;
               endb = (empty)?1'b1:1'b0;
               re = (~empty&~pause)?1'b1:1'b0;
            end
        endcase
    end


endmodule: crc_master_fsm

//////////////////////////////////////

//////////////////////////////////////
////         BITSTUFFER           ////
//////////////////////////////////////

module bit_stuff_fsm
    (output logic       s_out,start_nrzi,done,pause,
     output logic       clr_ones,clr_sp,incr_sp,incr_ones,
     input  logic [4:0] ones_count,      sp_count,
     input  logic       s_in, start,     endb,
     input  logic       clk,  rst_n);

    enum logic [1:0] {WAIT,READY,STUFF} bs_cs,bs_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          bs_cs <= WAIT;
        else
          bs_cs <= bs_ns;

    always_comb begin
        s_out = 1'bz;
        start_nrzi = 1'b0;
        done = 1'b0;
        pause = 1'b0;
        clr_ones = 1'b0;
        clr_sp = 1'b0;
        incr_sp = 1'b0;
        incr_ones = 1'b0;
        case(bs_cs)
            WAIT:begin
                bs_ns = (start)?READY:WAIT;
                start_nrzi = (start)?1'b1:1'b0;
                clr_ones = (start)?1'b1:1'b0;
                clr_sp = (start)?1'b1:1'b0;
            end
            READY:begin
                if(sp_count < 16)begin
                  bs_ns = READY;
                  incr_sp = 1;
                  s_out = s_in;
                end
                else
                  if(endb) begin
                    bs_ns = WAIT;
                    done = 1;
                  end
                  else begin
                    bs_ns = STUFF;
                    s_out = s_in;
                    if(s_in == 1)
                      incr_ones = 1;
                  end
            end
            STUFF:begin
                bs_ns = (endb)?WAIT:STUFF;
                done = (endb)?1'b1:1'b0;
                if(ones_count >= 6) begin
                  s_out = 0;
                  pause = 1;
                  clr_ones = 1;
                end
                else begin //ones_count < 6
                  s_out = s_in;
                  if(s_in == 1)
                    incr_ones = 1;
                  else
                    clr_ones = 1;
                end
            end
        endcase
    end

endmodule: bit_stuff_fsm

module bit_stuff
    (output logic s_out,start_nrzi,done,pause,
     input  logic s_in, start     ,endb,
     input  logic clk,  rst_n);

    
    /**********Counters**************/

    logic incr_ones,incr_sp,clr_ones,clr_sp;
    
    logic [4:0] ones_count, sp_count;

    counter #(5) ones(.clk,.rst_n,.en(incr_ones),
                      .clr(clr_ones),.count(ones_count));

    counter #(5) sp(.clk,.rst_n,.en(incr_sp),.clr(clr_sp),
                    .count(sp_count));

    /************************************/

    //FSM
    bit_stuff_fsm stuff(.*);

endmodule: bit_stuff
//////////////////////////////////////

//////////////////////////////////////
////       NRZI                   ////
//////////////////////////////////////

module nrzi_fsm
    (output logic start_dpdm, eop, sync_set,
     input  logic start_nrzi, done,clk, rst_n);

    enum logic [1:0] {WAIT,READY,SEND,BUF} nrzi_cs,nrzi_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          nrzi_cs <= WAIT;
        else
          nrzi_cs <= nrzi_ns;

    always_comb begin
        start_dpdm = 0;
        eop = 0;
        sync_set = 0;
        case(nrzi_cs)
            WAIT: begin
                nrzi_ns = (start_nrzi)?READY:WAIT;
                sync_set = (start_nrzi)?1'b1:1'b0;
                //start_dpdm = (start_nrzi)?1'b1:1'b0;
            end
            READY: begin
                nrzi_ns = SEND;
                start_dpdm = 1;
            end
            SEND: begin
                nrzi_ns = (done)?BUF:SEND;
            end
            BUF: begin
                nrzi_ns = WAIT;
                eop = 1;
            end
        endcase
    end
endmodule: nrzi_fsm


module nrzi
    (output logic start_dpdm, eop, s_out,
     input  logic s_in, start_nrzi, done,
     input  logic clk, rst_n);

   /************DFF***********/
   
   logic sync_set;
   logic d;

   assign d = ~(s_in^s_out);

   gen_dff dff(.clk,.rst_n,.d,.q(s_out),.rd(1'b1),
               .sync_set);
   /**************************/

   //FSM
   nrzi_fsm nz_fsm(.*);

endmodule: nrzi


//////////////////////////////////////

//////////////////////////////////////
////        DPDM                  ////
//////////////////////////////////////

`define J 2'b10
`define K 2'b01
`define X 2'b00

module dpdm
    (output logic [1:0] host_out,
     output logic       enable, sent_pkt,
     input  logic       s_in, start_dpdm, eop,
     input  logic       clk, rst_n);

    enum logic [2:0] {WAIT,OUT,EOP0,EOP1,EOP2} dpdm_cs,dpdm_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          dpdm_cs <= WAIT;
        else
          dpdm_cs <= dpdm_ns;

    always_comb begin
        enable = 0;
        sent_pkt = 0;
        host_out = 2'bz;
        case(dpdm_cs)
            WAIT: begin
                dpdm_ns = (start_dpdm)?OUT:WAIT;
            end
            OUT: begin
                enable = 1;
                if(eop) begin
                  dpdm_ns = EOP0;
                  //dpdm_ns = EOP1;
                  host_out = `X;
                end
                else begin
                  dpdm_ns = OUT;
                  if(s_in == 1)
                    host_out = `J;
                  else //s_in == 0
                    host_out = `K;
                end
            end
            EOP0: begin
                dpdm_ns = EOP1;
                enable = 1;
                host_out = `X;
            end
            EOP1:begin
                dpdm_ns = WAIT;
                enable = 1;
                host_out = `J;
                sent_pkt = 1;
            end
        endcase
    end

endmodule: dpdm

//////////////////////////////////////

//////////////////////////////////////
//////////BIT STREAM ENCODER    //////
//////////////////////////////////////

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
		output logic        pkt_received, 
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
	output logic       pkt_received,


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
		pkt_received = 0;
		case(cs)
			
			/* WAIT state */
			WAIT : begin
				if(pkt_type == `HSHAKE) begin
					ns = HS0;
					ld_h = 1;
					free_inbound = 0;
					pkt_received = 1;
				end
				else if(pkt_type == `TOKEN) begin
					ns = TOK0;
					ld_t = 1;
					free_inbound = 0;
					pkt_received = 1;
				end
				else if(pkt_type == `DATA) begin
					ns = DATA0;
					ld_d = 1;
					free_inbound = 0;
					pkt_received = 1;
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
					t_shft = 1;
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

/////////////////////////////////////

// Write your usb host here.  Do not modify the port list.
module usbHost
  (input logic clk, rst_L, 
  usbWires wires);

  //Deal with the wires
  logic enable;
  logic [1:0] host_out;

  assign wires.DP = enable?host_out[1]:1'bz;
  assign wires.DM = enable?host_out[0]:1'bz;

  /***************************************/

  // usbHost starts here!!

  /****Bit stream encoder****/
  //Inputs
  logic [1:0]  pkt_type;
  logic [71:0] data;
  logic [18:0] token;
  logic [7:0]  hshake;
  logic        sent_pkt;

  //Outputs
  logic pkt_received,free_inbound;
  logic [1:0] pkt_in;
  logic endr;
  logic s_out;

  bs_encoder bs(.clk,.rst_n(rst_L),.pkt_type,
                .data,.token,.hshake,
                .pkt_received,.free_inbound,
                .sent_pkt,.pkt_in,.endr,
                .s_out);
  /*******************************/
  /**************CRC**************/
  //Inputs
  logic pause;

  //Outputs
  logic start_b, endb;
  logic c_out;

  crc crc_ms(.clk,.rst_n(rst_L),.s_in(s_out),
             .endr,.pkt_in,.pause,.start_b,.endb,
             .s_out(c_out));

  /***********Bit stuffer************/

  //Outputs
  logic start_nrzi,done;
  logic s_out_stuff;

  bit_stuff bit_st(.clk,.rst_n(rst_L),.s_in(c_out),
                   .start(start_b),.endb,.done,.pause,
                   .start_nrzi,
                   .s_out(s_out_stuff));

  /**********************************/

  /************NRZI******************/
  //Outputs
  logic start_dpdm, eop, s_out_nrzi;

  nrzi nrzi_inst(.clk,.rst_n(rst_L),.start_dpdm,
                 .s_in(s_out_stuff),.start_nrzi,
                 .done,.eop,
                 .s_out(s_out_nrzi));

  /***********************************/

  /************DPDM*******************/
  
  dpdm dpdm_inst(.clk,.rst_n(rst_L),.s_in(s_out_nrzi),
                 .eop,.start_dpdm,.sent_pkt,
                 .enable,.host_out);
  
  /***********************************/
  
  /***************************************/

  /* Tasks needed to be finished to run testbenches */

  task prelabRequest
  // sends an OUT packet with ADDR=5 and ENDP=4
  // packet should have SYNC and EOP too
  (input bit [7:0] data);
	
	wait(free_inbound);
	pkt_type <= `TOKEN;
	token <= 19'b1000_0111_1010000_0010;
    //token <= 19'b1001_0110_1010000_0010;
	@(posedge clk);

	wait(free_inbound);
    @(posedge clk);
  endtask: prelabRequest

  task readData
  // host sends memPage to thumb drive and then gets data back from it
  // then returns data and status to the caller
  (input  bit [15:0]  mempage, // Page to write
   output bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: readData

  task writeData
  // Host sends memPage to thumb drive and then sends data
  // then returns status to the caller
  (input  bit [15:0]  mempage, // Page to write
   input  bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: writeData


endmodule: usbHost

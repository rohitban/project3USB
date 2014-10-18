
`define DATA_SIZE 7'd80
`define TOKEN_SIZE 6'd27
`define HSHAKE_SIZE 5'd16 

`define DATA 2'b11
`define TOKEN 2'b01
`define HSHAKE 2'b10

/* num of clock cycles to get residue from complmeneted remainder */ 
`define DELAY_T 6'd15  

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
                  //start_b = 1;
                end
            end
            TOK1: begin
                if(endr) begin
                  crc_ns = TOK2;
                  start_b = 1;
                end
                else begin
                  crc_ns = TOK1;
                  we = 1;
                  //re = 1;
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



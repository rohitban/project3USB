
`define DATA_SIZE 7'd96
`define TOKEN_SIZE 6'd32
`define HSHAKE_SIZE 5'd16 

`define DATA 2'b0
`define TOKEN 2'b1
`define HSHAKE 2'b10

`define SYNC 8'b0000_0001

/* num of clock cycles to get residue from complmeneted remainder */ 
`define DELAY 4'd8  

module crc(
	input  logic clk, rst_n,
	
	/* inputs from Bit Stream Encorder */
	input  logic 				s_in,
	input  logic 				start, endr,
	input  logic [1:0]  pkt_type,
	
	/* inputs from Bit Stuffer */
	input  logic        pause,
	/* ouputs to Bit Stuffer */
	output logic        start_b, endr_b,
	output logic				s_out
	);

	logic crc_cout;
	logic crc16_out;
	logic crc5_ready, crc5_done, crc5_start, crc5_rec;
	logic re, we;
	logic full, empty;
	logic bit_out, bit_in;
	logic incr, clr;
	logic [5:0] delay_count;

	assign sel_crctype = (pkt_type == `TOKEN) ? 0 : 1;

	crc5			tcrc(.clk, .rst_n, 
								 .s_in,
								 .crc5_start, .crc5_ready, .crc5_done,
								 .crc5_out, .crc5_rec);
	//crc16			dcrc(.*);

	fifo					q(.clk, .rst_n,
									.we, .re,
									.bit_in(s_in), .bit_out(s_out),
									.full, .empty);

	counter #(6)  delay(.clk, .rst_n,
											.clr, .en(incr),
											.count(delay_count));


	mux2to1 			 qmux(.Y(bit_in), 
										  .I0(s_in), .I1(crc_out),
										  .sel(sel_crc));

	mux2to1				cmux(.Y(crc_out), 
										 .I0(crc5_out), .I1(crc16_out),
										 .sel(sel_crctype));

	fsm 					 ctrl(.*);

endmodule : crc


module fsm(
	input  logic clk, rst_n, 
	output logic clr,
	/* inputs from bit stream encoder */
	input  logic 			 start, endr,
	input  logic [1:0] pkt_type,
	/* inputs/outputs from fifo */
	input  logic       empty,
	output logic 			 we, re,

	/* inputs/outputs from crc5 */
	output  logic 			 crc5_rec,
	input   logic       crc5_ready,
	input   logic			 crc5_done,
	output  logic       crc5_start,

	/* inputs/outputs from delay counter */
	input  logic [5:0] delay_count,
	output logic 			 incr,

	/* inputs/outputs from bit stuffer */
	input  logic       pause,
	output logic       start_b, endr_b,

	/* outputs to 2to1Mux */
	output logic 			 sel_crc
	);

	enum {WAIT, TOK0, TOK1, TOK2, TOK3, TOK4} cs, ns;

	always_ff@(posedge clk)
		if(~rst_n)
			cs <= WAIT;
		else
			cs <= ns;

	always_comb begin
		clr = 0; sel_crc = 0; re = 0; we = 0; incr = 0;	
		crc5_rec = 0; crc5_start = 0; start_b = 0; endr_b = 0;
		case(cs)
			WAIT : begin
				ns = (start) ? TOK0 : WAIT;
				clr = (start) ? 1 : 0;
			end
			TOK0 : begin 
				ns = (delay_count < 8) ? TOK0 : TOK1;
				we = 1;
				incr = 1;
				start_b = (delay_count < 8) ? 0 : 1;
			end
			TOK1 : begin
				if(delay_count < 16 && ~pause) begin
					ns = TOK1;
					we = 1;
					re = 1;
					incr = 1;
				end
				else if(delay_count < 16 && pause) begin
					ns = TOK1;
					we = 1;
					incr = 1;
				end
				else if(delay_count >=16 && pause) begin
					ns = TOK2;
					we = 1;
					crc5_start = 1;
				end
				else if(delay_count >= 16 && ~pause) begin
					ns = TOK2;
					we = 1;
					re = 1;
					crc5_start = 1;
				end
			end
			TOK2 : begin 
				ns = (endr) ? TOK3 : TOK2;
				we = (endr) ? 0 : 1;
				re = 1;
				we = (endr) ? 0 : 1;
			end
			TOK3 : begin
				ns = (crc5_ready) ? TOK4 : TOK3;
				re = 1;
			end			
			TOK4 : begin
				if(crc5_done)
					if(~empty) begin
						ns = TOK4;
						re = 1;
					end
					else begin
						ns = WAIT;
						crc5_rec = 1;
						endr_b = 1;
					end
				else begin
					ns = TOK4;
					we = 1;
					re = 1;
					sel_crc = 1;
				end
			end
		endcase
	end



endmodule: fsm




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



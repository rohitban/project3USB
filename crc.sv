
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
	
	/* inputs from Bit Stuffer */
	input  logic        pause,
	/* ouputs to Bit Stuffer */
	output logic        start_b, endr_b,
	output logic				s_out
	);


endmodule : crc


module fifo
  # (parameter W = 1)
  (input  logic        clk, rst_b,
   input  logic        we, re,
   input  logic        data_in,
   output logic        full, empty,
   output logic        data_out,
	 output logic [5:0]  count);

  logic [31:0] Q;
  bit [4:0]  putPtr, getPtr; //pointers wrap

  assign empty = (count == 0),
         full  = (count == 5'd32),
         data_out = Q[getPtr];

  //always_ff@(posedge clk, negedge rst_b)
  always_ff@(posedge clk, negedge rst_b)
  begin
    if (~rst_b) begin
      count <= 0;
      getPtr <= 0;
      putPtr <= 0;
    end
    else begin
      if(we & re & (!full) & (!empty)) begin
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        getPtr <= getPtr + 1;
      end
      else if(we & (!full)) begin
        Q[putPtr] <= data_in;
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



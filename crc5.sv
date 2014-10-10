
/* num of clock cycles to get residue from complmeneted remainder */ 
`define DELAY 7  
`define SYNC 8'b0000_0001

module crc5(
	input  logic clk, rst_n,
	
	/* inputs from Bit Stream Encorder */
	input  logic 				s_in,
	input  logic 				start, endr,
	
	/* inputs from Bit Stuffer */
	input  logic        pause,
	/* ouputs to Bit Stuffer */
	output logic        start_b, endr_b,
	output logic				s_out,





	);


endmodule : crc5


module fifo
  # (parameter W = 32)
  (input  bit         clk, rst_b,
   input  bit         we, re,
   input  pkt_t       data_in,
   output bit         full, empty,
   output pkt_t       data_out);

  pkt_t [3:0] Q;
  bit [1:0]  putPtr, getPtr; //pointers wrap
  bit [3:0]  count;

  assign empty = (count == 0),
         full  = (count == 4'd4),
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



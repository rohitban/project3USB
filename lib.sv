

module mult_dff
    #(parameter FFID = 0)
    (input  logic d, clk, rst_n, sync_set,rd, clr,
     output logic q);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          q <= 1;
        else if(clr)
		  	 q <= 0;
		  else
          if(sync_set)
            q <= 1;
          else if(rd)
            q <= d;

endmodule: mult_dff



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
    (input  logic d, clk, rst_n, sync_set,rd, clr,
     output logic q);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          q <= 0;
        else if(clr)
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

`define TOKEN 2'b01
`define DATA 2'b11
`define HSHAKE 2'b10

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


module fifo//can hold 32 elements
  (input  logic        clk, rst_n,
   input  logic        we, re,
   input  logic        bit_in,
   output logic        full, empty,
   output logic        bit_out,
	output logic [5:0]  count);
	
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



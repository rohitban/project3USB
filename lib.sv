


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




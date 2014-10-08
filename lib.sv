


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


module crc5_fsm
    (output logic       computing,done,
     output logic [4:0] sync_set,rd,
     output logic       addr_clr,comp_clr,store_clr,
     output logic       comp_shift, addr_shift,
     output logic       comp_ld, store_ld, clr_cnt, en,sel_comp,
     input  logic [3:0] crc_cnt,
     input  logic       start,rec,clk, rst_n);

    enum logic [1:0] {INIT,ADDR_PROC,COMP_PROC,WAIT} c5_cs, c5_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          c5_cs <= INIT;
        else
          c5_cs <= c5_ns;

    
    always_comb begin
        computing = 0;
        done = 0;
        sync_set = 0;
        rd = 5'b11111;
        {addr_clr,comp_clr,store_clr} = 0;
        {comp_shift,addr_shift} = 0;
        {comp_ld,store_ld} = 0;
        clr_cnt = 0;
        sel_comp = 0;
        en = 0;
        case(c5_cs)
            INIT: begin
                c5_ns = (start)?ADDR_PROC:INIT;
                if(start) begin
                    addr_clr = 1;
                    sync_set = 5'b11111;
                    clr_cnt = 1;
                    comp_clr = 1;
                    store_clr = 1;
                    computing = 1;
                end
            end
            ADDR_PROC: begin
                c5_ns = (crc_cnt==11)?COMP_PROC:ADDR_PROC;
                computing = 1;
                addr_shift = (crc_cnt!=11)?1'b1:1'b0;
                comp_shift = (crc_cnt==11)?1'b1:1'b0;
                clr_cnt = (crc_cnt==11)?1'b1:1'b0;
                comp_ld = (crc_cnt==11)?1'b1:1'b0;
                en = (crc_cnt!=11)?1'b1:1'b0;
                rd = (crc_cnt==11)?0:5'b11111;
            end
            COMP_PROC: begin
                c5_ns = (crc_cnt == 5)?WAIT:COMP_PROC;
                computing = 1;
                if(crc_cnt==5) begin
                  store_ld = 1;
                end
                else begin
                  comp_shift = 1;
                  en = 1;
                  sel_comp = 1;
                end
            end
            WAIT: begin
                c5_ns = (rec)?INIT:WAIT;
                done = (~rec)?1'b1:1'b0;
            end

        endcase
    end
        

endmodule: crc5_fsm

module crc_5
    (output logic [4:0] crc5,
     output logic       computing, done,
     input  logic       start, rec,
     input  logic        clk, rst_n);

    //DFF signals
    logic [4:0] dff_in, dff_out;
    logic [4:0] sync_set, rd;
   

    //{Addr,ENDP} piso signals
    logic [10:0] addr_out;
    logic        addr_shift, addr_clr;
    logic        addr_serial;

    //Generator complement signals
    logic  [4:0] comp_out;
    logic        comp_serial;
    logic        comp_clr, comp_ld, comp_shift;


    //Storage register signals
    logic        store_clr, store_ld;


    //ADDR,ENDP register
    piso_register #(11,11'b1010000_0010) addr_piso(.clk,.rst_n,.D( ),.ld( ),
                                                   .left(addr_shift), 
                                                   .Q(addr_out), 
                                                   .s_out(addr_serial),
                                                   .clr(addr_clr));
    //GEN COMPLEMENT register
    piso_register #(5,0) comp_piso(.clk,.rst_n,.D(~dff_out),.Q(comp_out),
                                   .clr(comp_clr),.ld(comp_ld),
                                   .left(comp_shift),.s_out(comp_serial));

    register #(5) storage_reg(.clk,.rst_n,.D(dff_out),.Q(crc5),
                              .clr(store_clr),.ld(store_ld));

    //Selection mux
    logic crc_in, sel_comp;

    mux2to1 #(1) mux_inst(.I0(addr_serial), .I1(comp_serial), 
                          .Y(crc_in), .sel(sel_comp));

    //Counter
    logic clr_cnt, en;
    logic [3:0] crc_cnt;

    counter #(4) crc_count(.clk,.rst_n,.count(crc_cnt),.clr(clr_cnt),.en);


   //CRC FFs
   assign dff_in[0] = dff_out[4]^crc_in,
          dff_in[1] = dff_out[0],
          dff_in[2] = dff_out[1]^(crc_in^dff_out[4]),
          dff_in[4:3] = dff_out[3:2];

   genvar i;
   generate
    for(i = 0; i < 5; i = i+1) 

      gen_dff #(i) gen_ff_inst(.clk,.rst_n,.sync_set(sync_set[i]),
                               .d(dff_in[i]),.q(dff_out[i]),.rd(rd[i]));

   endgenerate

   crc5_fsm fsm_inst(.*);

endmodule: crc_5

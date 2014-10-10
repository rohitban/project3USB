
module crc5_fsm
    (output logic [4:0] sync_set, rd,
     output logic       clr, comp_ld, comp_shift,
     output logic       store_ld,store_shift,sel_comp,
     output logic       clr_cnt,en, 
     output logic       crc5_ready, crc5_done,
     input  logic [4:0] crc_count,
     input  logic       crc5_start,
     input  logic       clk, rst_n);

    enum logic [1:0] {INIT,ADDR, PROC, STREAM} cs, ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= INIT;
        else
          cs <= ns;

endmodule: crc5_fsm

module crc5
    (output logic       crc5_out,
     output logic       crc5_ready,crc5_done,
     input  logic       crc5_start, s_in,
     input  logic        clk, rst_n);

    //DFF signals
    logic [4:0] dff_in, dff_out;
    logic [4:0] sync_set, rd;
   

    //Generator complement signals
    logic  [4:0] comp_out;
    logic        comp_serial;
    logic        clr, comp_ld, comp_shift;


    //Storage register signals
    logic  [4:0] store_out;
    logic        store_ld, clr;

    piso_register #(5,0) store_piso(.clk,.rst_n,.D(dff_out),.Q(store_out),
                                    .clr,.ld(store_ld),.left(store_shift),
                                    .s_out(crc5_out));

    //GEN COMPLEMENT register
    piso_register #(5,0) comp_piso(.clk,.rst_n,.D(~dff_out),.Q(comp_out),
                                   .clr,.ld(comp_ld),
                                   .left(comp_shift),.s_out(comp_serial));
    
    //Selection mux
    logic crc_in, sel_comp;

    mux2to1 #(1) mux_inst(.I0(s_in), .I1(comp_serial), 
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

endmodule: crc5


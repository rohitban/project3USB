
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

      gen_dff #(i) gen_ff_inst(.clk,.rst_n,.sync_set(sync_set[i]), .clr,
                               .d(dff_in[i]),.q(dff_out[i]),.rd(rd[i]));

   endgenerate

   crc5_fsm fsm_inst(.*);

endmodule: crc5


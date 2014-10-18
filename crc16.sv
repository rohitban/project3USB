/* 
 * crc16_fsm - This module takes the data and computes 
 * the remainder 
 */
module crc16_fsm
    (output logic [15:0] sync_set, rd,
     output logic        clr, comp_ld, comp_shift,
//     output logic        store_ld,store_shift,sel_comp,
     output logic        clr_cnt,en, 
     output logic        crc16_ready, crc16_done,
     input  logic [7:0]  crc_cnt,
     input  logic        crc16_start,crc16_rec,
     input  logic        clk, rst_n);
    enum logic [2:0] {INIT,ADDR, PROC, STREAM,BUFFER} cs, ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= INIT;
        else
          cs <= ns;

    always_comb begin
       sync_set = 16'h0;
       rd = 16'hffff;
       clr = 0;
       comp_ld = 0;
       comp_shift = 0;
     //  store_ld = 0;
     //  store_shift = 0;
     //  sel_comp = 0;
       clr_cnt = 0;
       en = 0;
       crc16_ready = 0;
       crc16_done = 0;
       case(cs)
         INIT:begin
            ns = (crc16_start)?ADDR:INIT;
            sync_set = (crc16_start)?16'hffff:0;
         end
         ADDR:begin
            ns = (crc_cnt < 64)?ADDR:PROC;
            rd = (crc_cnt < 64)?16'hffff:0;
            en  = (crc_cnt < 64)?1:0;
            clr_cnt = (crc_cnt < 64)?0:1;
            comp_ld = (crc_cnt < 64)?0:1;
         end
 /*        PROC: begin
            if(crc_cnt < 16)begin
              ns = PROC;
              comp_shift = 1;
              sel_comp = 1;
              en = 1;
            end
            else begin
              ns = STREAM;
              store_ld = 1;
              clr_cnt = 1;
              rd = 0;
            end
         end*/
         STREAM : begin
            if(crc_cnt < 16)begin
			  			ns = STREAM;
              comp_shift = 1;
              en = 1;
              crc16_ready = 1;
            end
						else
              ns = BUFFER;
         end
				 
         BUFFER: begin
            ns = (crc16_rec)?INIT:BUFFER;
            clr = (crc16_rec)?1:0;
            clr_cnt = (crc16_rec)?1:0;
            crc16_done = 1;
         end
         
       endcase
    end

endmodule: crc16_fsm

module crc16
    (output logic       crc16_out,
     output logic       crc16_ready,crc16_done,
     input  logic       crc16_start, s_in,crc16_rec,
     input  logic       clk, rst_n);

    //DFF signals
    logic [15:0] dff_in, dff_out;
    logic [15:0] sync_set, rd;
   

    //Generator complement signals
    logic  [15:0] comp_out;
    logic         comp_serial;
    logic         clr, comp_ld, comp_shift;


    //Storage register signals
//    logic  [15:0] store_out;
//    logic         store_ld;

//    piso_register #(16,0) store_piso(.clk,.rst_n,.D(dff_out),.Q(store_out),
//                                     .clr,.ld(store_ld),.left(store_shift),
//                                     .s_out(crc16_out));

    //GEN COMPLEMENT register
    piso_register #(16,0) comp_piso(.clk,.rst_n,.D(~dff_out),.Q(comp_out),
                                    .clr,.ld(comp_ld),
                                    .left(comp_shift),.s_out(crc16_out));
    
    //Selection mux
//    logic crc_in, sel_comp;

//    mux2to1 #(1) mux_inst(.I0(s_in), .I1(comp_serial), 
//                          .Y(crc_in), .sel(sel_comp));

    //Counter
    logic clr_cnt, en;
    logic [7:0] crc_cnt;

    counter #(8) crc_count(.clk,.rst_n,.count(crc_cnt),.clr(clr_cnt),.en);


   //CRC FFs
   assign dff_in[0] = dff_out[15]^s_in,
          dff_in[1] = dff_out[0],
          dff_in[2] = dff_out[1]^(s_in^dff_out[15]),
					dff_in[14:3] = dff_out[13:2],
					dff_in[15] = dff_out[14]^(s_in^dff_out[15]);

   genvar i;
   generate
    for(i = 0; i < 16; i = i+1) 

      gen_dff #(i) gen_ff_inst(.clk,.rst_n,.sync_set(sync_set[i]),
                               .d(dff_in[i]),.q(dff_out[i]),.rd(rd[i]));

   endgenerate

   crc16_fsm fsm_inst(.*);

endmodule: crc16

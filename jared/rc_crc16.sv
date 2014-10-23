/* 
 * crc16_fsm - This module takes the data and computes 
 * the remainder 
 */
module crc16_fsm
    (output logic [15:0] sync_set, rd,
     output logic        clr, comp_ld, comp_shift,
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
       clr_cnt = 0;
       en = 0;
       crc16_ready = 0;
       crc16_done = 0;
       case(cs)
         INIT:begin
            ns = (crc16_start)?ADDR:INIT;
            rd = (crc16_start)?16'hffff:0;
            //sync_set = (crc16_start)?16'hffff:0;
         end
         ADDR:begin
            ns = (crc_cnt < 63)?ADDR:BUFFER;
            rd = (crc_cnt < 63)?16'hffff:0;
            en  = (crc_cnt < 63)?1:0;
            clr_cnt = (crc_cnt < 63)?0:1;
            //comp_ld = (crc_cnt < 64)?0:1;
				comp_ld = (crc_cnt < 63) ? 0 : 1;
				crc16_done = (crc_cnt < 63) ? 0 : 1;
         end
         BUFFER: begin
            ns = (crc16_rec)?INIT:BUFFER;
            clr = (crc16_rec)?1:0;
            clr_cnt = (crc16_rec)?1:0;
            crc16_done = 1;
            sync_set = (crc16_rec)?16'hffff:0;
         end
         
       endcase
    end

endmodule: crc16_fsm

module rc_crc16
    (output logic        crc16_out,
	  output logic [15:0] crc16_val,
     output logic        crc16_ready,crc16_done,
     input  logic        crc16_start, s_in,crc16_rec,
     input  logic        clk, rst_n);

    //DFF signals
    logic [15:0] dff_in, dff_out;
    logic [15:0] sync_set, rd;
   

    //Generator complement signals
    logic  [15:0] comp_out;
    logic         comp_serial;
    logic         clr, comp_ld, comp_shift;


    //Storage register signals
    logic  [15:0] store_out;
    logic         store_ld;


    //GEN COMPLEMENT register
    register #(16) 		regi(.clk,.rst_n,.D(~dff_out),.Q(crc16_val),
                               .clr,.ld(comp_ld));
    

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

      inv_gen_dff #(i) gen_ff_inst(.clk,.rst_n,.sync_set(sync_set[i]), .clr(1'b0),
                               .d(dff_in[i]),.q(dff_out[i]),.rd(rd[i]));

   endgenerate

   crc16_fsm fsm_inst(.*);

endmodule: rc_crc16

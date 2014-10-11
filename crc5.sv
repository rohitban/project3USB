
module crc5_fsm
    (output logic [4:0] sync_set, rd,
     output logic       clr, comp_ld, comp_shift,
     output logic       store_ld,store_shift,sel_comp,
     output logic       clr_cnt,en, 
     output logic       crc5_ready, crc5_done,
     input  logic [4:0] crc_cnt,
     input  logic       crc5_start,crc5_rec,
		 input  logic 			send, //test erase this afterwards
     input  logic       clk, rst_n);
    enum logic [2:0] {INIT,ADDR, PROC, STREAM,BUFFER} cs, ns;

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
       store_ld = 0;
       store_shift = 0;
       sel_comp = 0;
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
            ns = (crc_cnt < 11)?ADDR:PROC;
            rd = (crc_cnt < 11)?5'b11111:0;
            en  = (crc_cnt < 11)?1:0;
            clr_cnt = (crc_cnt < 11)?0:1;
            comp_ld = (crc_cnt < 11)?0:1;
         end
         PROC: begin
            if(crc_cnt < 5)begin
              ns = PROC;
              comp_shift = 1;
              sel_comp = 1;
              en = 1;
            end
            else begin
              ns = STREAM;
              store_ld = 1;
              //crc5_ready = 1;
              clr_cnt = 1;
            end
         end
         STREAM : begin
            if(crc_cnt < 5)begin
							if(send) begin
              	ns = STREAM;
              	store_shift = 1;
              	en = 1;
              	crc5_ready = 1;
            	end
							else begin 
								ns = STREAM;
								crc5_ready = 1;
							end
						end
            else begin
							crc5_done = 1;
              ns = BUFFER;
            end
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
		 input  logic  send, // erase afterward !!!!!!!
     input  logic       clk, rst_n);
    //DFF signals
    logic [4:0] dff_in, dff_out;
    logic [4:0] sync_set, rd;
   

    //Generator complement signals
    logic  [4:0] comp_out;
    logic        comp_serial;
    logic        clr, comp_ld, comp_shift;


    //Storage register signals
    logic  [4:0] store_out;
    logic        store_ld;

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
    logic [4:0] crc_cnt;

    counter #(5) crc_count(.clk,.rst_n,.count(crc_cnt),.clr(clr_cnt),.en);


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


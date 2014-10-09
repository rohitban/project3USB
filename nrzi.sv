
module nrzi_fsm
    (output logic start_dpdm, eop, sync_set,
     input  logic start_nrzi, done,clk, rst_n);

    enum logic {WAIT,SEND} nrzi_cs,nrzi_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          nrzi_cs <= WAIT;
        else
          nrzi_cs <= nrzi_ns;

    always_comb begin
        start_dpdm = 0;
        eop = 0;
        sync_set = 0;
        case(nrzi_cs)
            WAIT: begin
                nrzi_ns = (start_nrzi)?SEND:WAIT;
                sync_set = (start_nrzi)?1'b1:1'b0;
                start_dpdm = (start_nrzi)?1'b1:1'b0;
            end
            SEND: begin
                nrzi_ns = (done)?WAIT:SEND;
                eop = (done)?1'b1:1'b0;
            end
        endcase
    end
endmodule: nrzi_fsm


module nrzi
    (output logic start_dpdm, eop, s_out,
     input  logic s_in, start_nrzi, done,
     input  logic clk, rst_n);

   /************DFF***********/
   
   logic sync_set;
   logic d;

   assign d = ~(s_in^s_out);

   gen_dff dff(.clk,.rst_n,.d,.q(s_out),.rd(1'b1),
               .sync_set);
   /**************************/

   //FSM
   nrzi_fsm nz_fsm(.*);

endmodule: nrzi

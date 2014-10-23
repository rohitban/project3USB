
module nrzi_decode_fsm
    (output logic start_unstuff, end_unstuff, clr,
     input  logic start_rc_nrzi, end_rc_nrzi,clk, rst_n);

    enum logic [1:0] {WAIT,READY,DECODE} cs,ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= WAIT;
        else
          cs <= ns;

    always_comb begin
        start_unstuff = 0;
        end_unstuff = 0;
        clr = 0;
        case(cs)
            WAIT: begin
                ns = (start_rc_nrzi)?READY:WAIT;
            end
            READY: begin
                ns = DECODE;
                start_unstuff = 1;
            end
            DECODE: begin
                ns = (end_rc_nrzi)?WAIT:DECODE;
                end_unstuff = (end_rc_nrzi)?1:0;
                clr = (end_rc_nrzi)?1:0;
            end
        endcase
    end
endmodule: nrzi_decode_fsm


module decode_nrzi
    (output logic start_unstuff, end_unstuff, s_out,
     input  logic s_in, start_rc_nrzi, end_rc_nrzi,
     input  logic clk, rst_n);

   /************DFF***********/
   
   logic clr;
   logic q;


   mult_dff dff(.clk,.rst_n,.d(s_in),.q,.rd(1'b1),
               .sync_set( ), .clr);

   assign s_out = ~(q^s_in);

   /**************************/

   //FSM
   nrzi_decode_fsm nz_fsm(.*);

endmodule: decode_nrzi

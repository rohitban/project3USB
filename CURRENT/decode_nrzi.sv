
module nrzi_decode_fsm
    (output logic start_unstuffer, end_unstuffer, clr, rc_nrzi_wait,
     input  logic start_rc_nrzi, end_rc_nrzi,clk, rst_n, abort);

    enum logic [1:0] {WAIT,READY,DECODE} cs,ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= WAIT;
		  else if(abort)
		  	 cs <= WAIT;
        else
          cs <= ns;

    always_comb begin
	 	  rc_nrzi_wait = 0;
        start_unstuffer = 0;
        end_unstuffer = 0;
        clr = (abort)? 1 : 0;
        case(cs)
            WAIT: begin
                ns = (start_rc_nrzi)?READY:WAIT;
            	 start_unstuffer = (start_rc_nrzi) ? 1 : 0;
					 //rc_nrzi_wait = (start_rc_nrzi) ? 0 : 1;
					 rc_nrzi_wait = 1;
				end
            READY: begin
                ns = DECODE;
                //start_unstuffer = 1;
            end
            DECODE: begin
                ns = (end_rc_nrzi)?WAIT:DECODE;
                end_unstuffer = (end_rc_nrzi)?1:0;
                clr = (end_rc_nrzi)?1:0;
            end
        endcase
    end
endmodule: nrzi_decode_fsm


module decode_nrzi
    (output logic start_unstuffer, end_unstuffer, s_out, rc_nrzi_wait,
     input  logic s_in, start_rc_nrzi, end_rc_nrzi,
     input  logic clk, rst_n, abort);

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

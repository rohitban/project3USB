


module rc_dpdm
    (input  logic 			rst_n, clk,
		 
		 /*outputs to rc_nrzi */
		 output logic        s_out,
		 output logic	      start_rc_nrzi, 
		 output logic 		   end_rc_nrzi,

		 /* inputs from protocolFSM */
		 input  logic        receive_data,   //expecting a 64bit data
		 input  logic		   receive_hshake, //expecting a handshake
		 input  logic 		   rc_EOPerr,	   
		 //protocolFSM signals rc_dpdm that it received the error signal

		 /* outputs to every module - i.e. rc_nrzi, rc_crc, bitUnstuffer etc */
		 output logic        abort,

		 /* ouputs to protocolFSM */
		 output logic 			EOP_error,      //EOP error
		 output logic 			got_sync, 		 //found SYNC!
	
   	 input  logic [1:0]  bus_in,
     	 input  logic        enable);

    enum logic [3:0] {WAIT, INIT,ONLYK,KJ,KJK,KJKJ,KJKJK,KJKJKJ,KJKJKJK,KJKJKJKK,
          RC,BUF,RC_ERROR,EOP0,EOP1} cs,ns;
    
    logic seen_J, seen_K, seen_X;

    logic clr, en;
    logic [6:0] count;

    assign seen_J = (~enable && (bus_in == `J));
    assign seen_K = (~enable && (bus_in == `K));
    assign seen_X = (~enable && (bus_in == `X));

    counter #(7) bit_count(.count,.clr,.en,.clk,.rst_n);

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= INIT;
        else
          cs <= ns;

    always_comb begin
        s_out = 0;
        end_msg = 0;
        EOP_error = 0;
        got_sync = 0;
        start_nrzi = 0;
        complete = 0;
        case(cs)
						WAIT: begin
								ns = (receive_data | receive_hshake) ? INIT: WAIT;
						end
            INIT: begin
                ns = (seen_K)?ONLYK:INIT;
            end
            ONLYK: begin
                ns = (seen_J)?KJ:INIT;
            end
            KJ: begin
                ns = (seen_K)?KJK:INIT;
            end
            KJK: begin
                ns = (seen_J)?KJKJ:INIT;
            end
            KJKJ: begin
                ns = (seen_K)?KJKJK:INIT;
            end
            KJKJK: begin
                ns = (seen_J)?KJKJKJ:INIT;
            end
            KJKJKJ: begin
                ns = (seen_K)?KJKJKJK:INIT;
            end
            KJKJKJK: begin
                ns = (seen_K)?RC:INIT;
            end
            RC: begin
                if(seen_X) begin
                  ns = EOP0;
                  end_msg = 1;
                  clr  = 1;
                end
                else if(count >= 88) begin
                  ns = RC_ERROR;
                  end_msg = 1;
                  clr = 1;
                end
                else
                  ns = RC;
                  if(seen_K) begin
                    s_out = 0;
                    en = 1;
                  end
                  else if(seen_J) begin
                    s_out = 1;
                    en = 1;
                  end                
            end
            EOP0: begin
                ns = (seen_X)?EOP1:RC_ERROR;
            end
            EOP1: begin
                ns = (seen_J)?BUF:RC_ERROR;
            end
            BUF: begin
                ns = INIT;
                complete = 1;
            end
            RC_ERROR: begin
                ns = (rc_EOPerr)?INIT:RC_ERROR;
                complete = 1;
								end_nrzi = 1;
                EOP_error = 1;                
            end
        endcase
    end

endmodule: rc_dpdm

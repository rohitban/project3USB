`define DATA_BITS 7'd101
`define HSHAKE_BITS 7'd8

`define J 2'b10
`define K 2'b01
`define X 2'b00

module rc_dpdm
        (input  logic        rst_n, clk,
		 
		 /*outputs to rc_nrzi */
		 output logic        s_out,
		 output logic	     start_rc_nrzi, 
		 output logic 		 end_rc_nrzi,

		 /* inputs from protocolFSM */
         //Note that the receive_data/hshake must be constantly asserted
         //by the protocolFSM while it waits for a incoming pkt
		 input  logic        receive_data,   //expecting a 64bit data
		 input  logic		 receive_hshake, //expecting a handshake	   
		 

		 //Synchronous reset(DA BIG HAMMERRR!!!!!!)
		 input logic         abort,
         //Abort should take priority so it is the same as a synchronous reset

		 /* ouputs to protocolFSM */
		 output logic 		 EOP_error,      //EOP error
		 output logic 		 got_sync, 		 //found SYNC!
		 output logic      rc_dpdm_wait,	
    	 input  logic [1:0]  bus_in,
     	 input  logic        enable);

    enum logic [3:0] {WAIT,ONLYK,KJ,KJK,KJKJ,KJKJK,KJKJKJ,KJKJKJK,
                      RC_HS,RC_DATA,EOP1,EOP2,ERROR} cs,ns;
    
    //logic s_out;

    logic seen_J, seen_K, seen_X;

    
    assign seen_J = (~enable && (bus_in == `J));
    assign seen_K = (~enable && (bus_in == `K));
    assign seen_X = (~enable && (bus_in == `X));


    /*
    mult_dff m1(.clk,.rst_n,.sync_set( ),.rd(1'b1),.clr,
                .d(s_out),.q(buffered_out));
    */

    //Counter logic
    logic clr,en;
    logic [6:0] count;

    counter #(7) bit_count(.count,.clr,.en,.clk,.rst_n);

    //MUX logic
    logic [6:0] mux_out;
    logic       sel_hs;

    mux2to1 #(7) size_mux(.I0(`DATA_BITS),.I1(`HSHAKE_BITS),
                          .Y(mux_out),.sel(sel_hs));

    //Register connections
    logic [6:0] total_bits;
    logic       ld;

    register #(7) bit_reg(.D(mux_out),.Q(total_bits),
                          .ld,.clr,.rst_n,.clk);


    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          cs <= WAIT;
        else if(abort)
          cs <= WAIT;//abort is like a synchronous reset
        else
          cs <= ns;

    always_comb begin
        rc_dpdm_wait = 0;
		  
		  s_out = 0;
        end_rc_nrzi = 0;
        start_rc_nrzi = 0;
        EOP_error = 0;
        got_sync = 0;

        ld = 0;
        sel_hs = 0;
        en = 0;
        clr = (abort)?1:0;

        case(cs)
		    WAIT: begin
			    if(seen_K&&receive_hshake) begin
                  ns = ONLYK;
                  sel_hs = 1;
                  ld = 1;
						rc_dpdm_wait = 0;
                end
                else if(seen_K&&receive_data) begin
                  ns = ONLYK;
                  ld = 1;
						rc_dpdm_wait = 0;
                end
                else begin
                  ns = WAIT;
						rc_dpdm_wait = 1;
                end
			end
            ONLYK: begin
                ns = (seen_J)?KJ:WAIT;
            end
            KJ: begin
                ns = (seen_K)?KJK:WAIT;
            end
            KJK: begin
                ns = (seen_J)?KJKJ:WAIT;
            end
            KJKJ: begin
                ns = (seen_K)?KJKJK:WAIT;
            end
            KJKJK: begin
                ns = (seen_J)?KJKJKJ:WAIT;
            end
            KJKJKJ: begin
                ns = (seen_K)?KJKJKJK:WAIT;
            end
            KJKJKJK: begin
                if(seen_K)
                  if(receive_hshake)
                    ns = RC_HS;
                  else//receive_data must be asserted
                    ns = RC_DATA;
                got_sync = (seen_K)?1:0;
                start_rc_nrzi = (seen_K)?1:0;
            end

            RC_HS: begin
                if(count < total_bits) begin
                  if(seen_K) begin
                    ns = RC_HS;
                    s_out = 0;
                    en = 1;
                  end
                  else if(seen_J) begin
                    ns = RC_HS;
                    s_out = 1;
                    en = 1;
                  end
                  else begin 
                    //We see neither J nor K on the bus
                    //So we have unknown data
                    ns = ERROR;
                    clr = 1;
                    EOP_error = 1;
                  end
                end
                else begin
                  ns = (seen_X)?EOP1:ERROR;
                  clr = 1;
                  end_rc_nrzi = 1;
                  EOP_error = (seen_X)?0:1;
                end
            end
            
            RC_DATA:begin
                if(count < total_bits) begin
                  if(seen_K) begin
                    ns = RC_DATA;
                    en = 1;
                    s_out = 0;
                  end
                  else if(seen_J) begin
                    ns = RC_DATA;
                    en = 1;
                    s_out = 1;
                  end
                  else begin //seen_X 
                    ns = EOP1;
                    clr = 1;
                    end_rc_nrzi = 1;
                  end                  
                end
                else begin
                  ns = ERROR;
                  end_rc_nrzi = 1;
                  EOP_error = 1;
                  clr = 1;
                end
            end

            EOP1: begin
                ns = (seen_X)?EOP2:ERROR;
                EOP_error = (seen_X)?0:1;
            end
            EOP2: begin
                ns = (seen_J)?WAIT:ERROR;
                EOP_error = (seen_J)?0:1;
            end
            ERROR: begin
                $display("BLOOOOOODDYYYYY MURDERRRRRR!!");
                ns = (abort)?WAIT:ERROR;
                EOP_error = 1;                
            end
        endcase
    end

endmodule: rc_dpdm

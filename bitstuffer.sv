

module bit_stuff_fsm
    (output logic       s_out,start_nrzi,done,pause,
     output logic       clr_ones,clr_sp,incr_sp,incr_ones,
     input  logic [4:0] ones_count,      sp_count,
     input  logic       s_in, start,     endr,
     input  logic       clk,  rst_n);

    enum logic [1:0] {WAIT,READY,STUFF} bs_cs,bs_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          bs_cs <= WAIT;
        else
          bs_cs <= bs_ns;

    always_comb begin
        s_out = 1'bz;
        start_nrzi = 1'b0;
        done = 1'b0;
        pause = 1'b0;
        clr_ones = 1'b0;
        clr_sp = 1'b0;
        incr_sp = 1'b0;
        incr_ones = 1'b0;
        case(bs_cs)
            WAIT:begin
                bs_ns = (start)?READY:WAIT;
                start_nrzi = (start)?1'b1:1'b0;
                clr_ones = (start)?1'b1:1'b0;
                clr_sp = (start)?1'b1:1'b0;
            end
            READY:begin
                if(sp_count < 16)begin
                  bs_ns = READY;
                  incr_sp = 1;
                  s_out = s_in;
                end
                else
                  if(endr) begin
                    bs_ns = WAIT;
                    done = 1;
                  end
                  else begin
                    bs_ns = STUFF;
                    s_out = s_in;
                    if(s_in == 1)
                      incr_ones = 1;
                  end
            end
            STUFF:begin
                bs_ns = (endr)?WAIT:STUFF;
                done = (endr)?1'b1:1'b0;
                if(ones_count >= 6) begin
                  s_out = 0;
                  pause = 1;
                  clr_ones = 1;
                end
                else begin //ones_count < 6
                  s_out = s_in;
                  if(s_in == 1)
                    incr_ones = 1;
                end
            end
        endcase
    end

endmodule: bit_stuff_fsm

module bit_stuff
    (output logic s_out,start_nrzi,done,pause,
     input  logic s_in, start     ,endr,
     input  logic clk,  rst_n);

    
    /**********Counters**************/

    logic incr_ones,incr_sp,clr_ones,clr_sp;
    
    logic [4:0] ones_count, sp_count;

    counter #(5) ones(.clk,.rst_n,.en(incr_ones),
                      .clr(clr_ones),.count(ones_count));

    counter #(5) sp(.clk,.rst_n,.en(incr_sp),.clr(clr_sp),
                    .count(sp_count));

    /************************************/

    //FSM
    bit_stuff_fsm stuff(.*);

endmodule: bit_stuff

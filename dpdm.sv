

`define J 2'b10
`define K 2'b01
`define X 2'b00

module dpdm
    (output logic [1:0] host_out,
     output logic       enable, sent_pkt,
     input  logic       s_in, start_dpdm, eop,
     input  logic       clk, rst_n);

    enum logic [2:0] {WAIT,OUT,EOP0,EOP1,EOP2} dpdm_cs,dpdm_ns;

    always_ff@(posedge clk, negedge rst_n)
        if(~rst_n)
          dpdm_cs <= WAIT;
        else
          dpdm_cs <= dpdm_ns;

    always_comb begin
        enable = 0;
        sent_pkt = 0;
        host_out = 2'bz;
        case(dpdm_cs)
            WAIT: begin
                dpdm_ns = (start_dpdm)?OUT:WAIT;
            end
            OUT: begin
                enable = 1;
                if(eop) begin
                  dpdm_ns = EOP0;
                  host_out = `X;
                end
                else begin
                  dpdm_ns = OUT;
                  if(s_in == 1)
                    host_out = `J;
                  else //s_in == 0
                    host_out = `K;
                end
            end
            EOP0: begin
                dpdm_ns = EOP1;
                enable = 1;
                host_out = `X;
            end
            EOP1:begin
                dpdm_ns = WAIT;
                enable = 1;
                host_out = `J;
                sent_pkt = 1;
            end
        endcase
    end

endmodule: dpdm

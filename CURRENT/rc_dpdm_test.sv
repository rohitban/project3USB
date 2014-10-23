

module rc_dpdm_tb;
    logic rst_n, clk;
    
    /*DPDM connections*/

    //Outputs:
    logic s_out;
    logic start_rc_nrzi, end_rc_nrzi;
    logic got_sync, EOP_error;

    //Inputs:
    logic [1:0] bus_in;
    logic       enable;
    logic       abort;
    logic       receive_data,receive_hshake;
    /********************/

    rc_dpdm rc_dpdm_inst(.clk,.rst_n,.s_out,.start_rc_nrzi,.end_rc_nrzi,
                         .receive_data,.receive_hshake,.abort,.EOP_error,
                         .got_sync,.bus_in,.enable);

    //nrzi stuff
    logic end_unstuffer, nrzi_out;
    logic start_unstuffer;

    decode_nrzi nrzi_rec(.clk,.rst_n,.s_in(s_out),.s_out(nrzi_out),
                  .start_rc_nrzi,.end_rc_nrzi,
                  .start_unstuffer,.end_unstuffer);

    //SIPO stuff
    logic [7:0] Q;
    logic en;

    sipo_register #(8) reg_inst(.clk,.en,.left(1'b1),.s_in(nrzi_out),.Q);
    

    initial begin
        clk = 0;
        rst_n = 0;
        rst_n <= #1 1;
        forever #5 clk = ~clk;
    end
   
    string sync;
    string data;
    string in;
    int n;

    initial begin
        $monitor("Q is (%b)",Q);
        sync = "KJKJKJKK";
        data = "JJKJJKKK";
        bus_in <= `X;
        enable  <= 0;
        receive_data <= 0;
        receive_hshake <= 0;
        @(posedge clk);
        receive_hshake <= 1;
        for(int  i = 0; i < sync.len();i++) begin
            in = sync[i];
            if(in == "K")
              bus_in <= `K;
            else if(in == "J")
              bus_in <= `J;
            else //in == "X"
              bus_in <= `X;
            @(posedge clk);
        end
        $display("At this point the SYNC has been put in and got_sync is (%b)",
                 got_sync);
        $display("At this point SYNC has been put in and nrzi start is (%b)",
                 start_rc_nrzi);
        
        bus_in <= `J;
        en <= 1;
        @(posedge clk);
        $display("Before shifting in start_unstuffer is %b",start_unstuffer);
        for(int i = 1; i < data.len();i++) begin
          in = data[i];
            if(in == "K")
              bus_in <= `K;
            else if(in == "J")
              bus_in <= `J;
            else //in == "X"
              bus_in <= `X;
            @(posedge clk);
        end

        bus_in <= `X;
        en <= 0;

        @(posedge clk);

        wait(end_rc_nrzi);
        $strobe("After entire hshake packet has been given currently in (%s)",
                rc_dpdm_inst.cs.name);
        bus_in <= `X;
        @(posedge clk);
        bus_in <= `J;
        @(posedge clk);
        $strobe("At the end of simulation state is(%s)",rc_dpdm_inst.cs.name);
        #2;
        $finish;
    end

endmodule: rc_dpdm_tb

`define TOKEN 2'b01

module stuff_test;
	logic clk, rst_n;
	logic s_in, endr;
	logic [1:0] pkt_in;
	logic pause, start_b, endb, s_out;
	logic [32:0] Q;
	logic        en, left;

    //Bit stuffer
    logic stuff_out, start_nrzi;
    logic done;
    
    //NRZI
    logic nrzi_out, start_dpdm;
    logic eop;

	crc     dut(.*);
    
    bit_stuff device(.clk,.rst_n,.s_in(s_out),
                     .start_nrzi,.done,.pause,
                     .s_out(stuff_out),.start(start_b),
                     .endb);

    nrzi mod(.clk,.rst_n,.s_in(stuff_out),.start_dpdm,
             .start_nrzi,.eop,.s_out(nrzi_out),.done);
    
	sipo_register #(33) s1(.s_in(nrzi_out), .Q, .en,.left,.clk);

    string in;
    string data;
    int n;

	initial begin
		clk = 0;
		rst_n = 0;
		rst_n <= #1 1;
		forever #5 clk = ~clk;
	end

	initial begin
        $monitor($stime, "  Q = %b",Q);
        data = "000000011000000111111101111";
		endr <= 0;
        
        en<=0;
        left<=0;
		@(posedge clk);
		endr <= 0;
		pkt_in <= `TOKEN;
		@(posedge clk);
		pkt_in <= 0;

        n = data.len();

        for(int i = 0; i < n; i++) begin
          in = data.getc(i);
          /*
          if((in.atoi()!= 0)||(in.atoi()!= 1))
            $display("Error in is %d",in.atoi());*/
          s_in <= in.atoi();
          @(posedge clk);
        end
        endr <= 1;

	    @(posedge clk);
        $display("Start_b is (%b)",start_b);
        @(posedge clk);
        en <= 1;
        left <= 1;

        endr <= 0;
        wait(dut.crc5_done);
        $display("Currently in state (%s)",dut.ctrl.crc_cs.name);
        wait(eop);
        en <= 0;
        left <= 0;
        @(posedge clk);
        @(posedge clk);
        $display("Simulation completed with crc at state (%s)",
                  dut.ctrl.crc_cs.name);
        $display("Simulation completed with crc5 at state(%s)",
                 dut.tcrc.fsm_inst.cs.name);
        $display("Simulation completed with bitstuffer at state(%s)",
                 device.stuff.bs_cs.name);
        $display("Simulation completed with nrzi at state(%s)",
                  mod.nz_fsm.nrzi_cs.name);
		$finish;
	end



endmodule: stuff_test

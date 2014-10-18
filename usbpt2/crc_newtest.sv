`define TOKEN 2'b01

module crc_test;
	logic clk, rst_n;
	logic s_in, endr;
	logic [1:0] pkt_in;
	logic pause, start_b, endb, s_out;
	logic [31:0] Q;
	logic        en, left;


	crc     dut(.*);

	sipo_register #(32) s1(.s_in(s_out), .Q, .en,.left,.clk);

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
        data = "000000011000011110100000010";
		endr <= 0;
        pause<=0;
        
        en<=0;
        left<=0;
		@(posedge clk);
		endr <= 0;
		pause <= 0;
		pkt_in <= `TOKEN;
		@(posedge clk);
		pkt_in <= 0;

        n = data.len();

        for(int i = 0; i < n; i++) begin
          in = data.getc(i);
          if((in.atoi()!= 0)||(in.atoi()!= 1))
            $display("Error in is %d",in.atoi());
          s_in <= in.atoi();
          @(posedge clk);
        end
        endr <= 1;

	    @(posedge clk);
        $display("Start_b is (%b)",start_b);
        en <= 1;
        left <= 1;

        endr <= 0;
        wait(dut.crc5_done);
        $display("Currently in state (%s)",dut.ctrl.crc_cs.name);
        wait(dut.empty);
        en <= 0;
        left <= 0;
        @(posedge clk);
        @(posedge clk);
        $display("Simulation completed at state (%s)",dut.ctrl.crc_cs.name);
		$finish;
	end



endmodule: crc_test

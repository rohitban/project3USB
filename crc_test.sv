`define TOKEN 2'b1

module crc_test;
	logic clk, rst_n;
	logic s_in, start, endr;
	logic [1:0] pkt_type;
	logic pause, start_b, endr_b, s_out;
	logic [26:0] data;

	crc     dut(.*);

	assign data = 27'b0000_0001_1000_0001_0000_1000_111;

	initial begin
		clk = 0;
		rst_n = 0;
		rst_n <= 1;
		forever #4 clk = ~clk;
	end

	initial begin
		$monitor($stime,
						 "  cs(%s) ns(%s) s_in(%b), start(%b), endr(%b), pkt_type(%b) start_b(%b), endr_b(%b), s_out(%b)\
							FIFO empty(%b), crc5_ready(%b), crc5_done(%b),crc5_start(%b)", 
						  dut.ctrl.cs, dut.ctrl.ns, s_in, start, endr, pkt_type, start_b,
							endr_b, s_out, dut.empty, dut.crc5_ready, dut.crc5_done, dut.crc5_start);
		@(posedge clk);
		endr <= 0;
		pause<=0;
		start <= 1; 
		pkt_type <= `TOKEN;
		@(posedge clk);
		start <= 0; s_in <= 0;  //SYNC[7]

		@(posedge clk);
		s_in <= 0;  //SYNC[6]
		@(posedge clk);
		s_in <= 0;  //SYNC[5]
		@(posedge clk);
		s_in <= 0;  //SYNC[4]
		@(posedge clk);
		s_in <= 0;  //SYNC[3]
		@(posedge clk);
		s_in <= 0;  //SYNC[2]
		@(posedge clk);
		s_in <= 0;  //SYNC[1]
		@(posedge clk);
		s_in <= 1;  //SYNC[0]
		@(posedge clk);
		s_in <= 1;  //PID[7]
		@(posedge clk);
		s_in <= 0;  //PID[6]
		@(posedge clk);
		s_in <= 0;  //PID[5]
		@(posedge clk);
		s_in <= 0;  //PID[4]
		@(posedge clk);
		s_in <= 0;  //PID[3]
		@(posedge clk);
		s_in <= 0;  //PID[2]
		@(posedge clk);
		s_in <= 0;  //PID[1]
		@(posedge clk);
		s_in <= 1;  //PID[0]
		@(posedge clk);
		s_in <= 0;  //ADDR[6]
		@(posedge clk);
		s_in <= 0;  //ADDR[5]
		@(posedge clk); 
		s_in <= 0;  //ADDR[4]
		@(posedge clk);
		s_in <= 0;  //ADDR[3]
		@(posedge clk);
		s_in <= 1;  //ADDR[2]
		@(posedge clk);
		s_in <= 0;  //ADDR[1]
		@(posedge clk);
		s_in <= 0;  //ADDR[0]
		@(posedge clk);
		s_in <= 0;  //ENDP[4]
		@(posedge clk);
		s_in <= 1;  //ENDP[3]
		@(posedge clk);
		s_in <= 1;  //ENDP[2]
		@(posedge clk);
		s_in <= 1;  //ENDP[1]
		@(posedge clk);	
		endr <= 1;
		@(posedge clk);
		endr <= 0;
		for(int i = 0; i < 150; i++) begin
			@(posedge clk);	
		end
		@(posedge clk);	
		@(posedge clk);	
		@(posedge clk);
		#4 $finish;
	end



endmodule: crc_test

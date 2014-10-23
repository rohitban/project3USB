module pid_test;
	logic clk, rst_n, start_decode, s_in, end_PID;
	logic PID_checked, PID_valid;

	pid_checker   dut(.*);

	string pid;
	string data;
	string in;
	int n;

	initial begin
		rst_n = 0;
		rst_n <= 1;
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
	$monitor($time, , 
				"cs(%s), ns(%s), count = %d, PID_checked = %b, PID_valid = %b, pid = %b, cpid = %b",
				 dut.fsm.cs.name, dut.fsm.ns.name, dut.count, 
				 PID_checked, PID_valid,
				 dut.pid, dut.cpid);
	//pid = "11000011";
	pid = "1100001111110111011111011011010101111011011111010101110101111111010100111101101111000101";
	n = pid.len();
	start_decode <= 0;
	@(posedge clk);
	@(posedge clk);
	start_decode <= 1;
	in = pid.getc(0);
	s_in <= in.atoi();
	@(posedge clk);
	start_decode <= 0;
	for(int i = 1; i < n; i++) begin
		in = pid.getc(i);
		$display("s_in is %s", in);
		s_in <= in.atoi();
		@(posedge clk);
		end
	@(posedge clk);
	end_PID <= 1;
	@(posedge clk);
	end_PID <= 0;
	@(posedge clk);
	#2 $finish;
	end
endmodule : pid_test

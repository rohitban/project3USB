module bs_decoder_test;
	logic clk, rst_n, start_decode, end_decode;
	logic s_in, s_out, start_rc_crc, end_rc_crc, PID_error;
	logic rc_PIDerror;

	bs_decoder   dut(.*);
	
	string pid;
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
				"cs(%s), ns(%s), s_out = %b, PID_checked = %b, PID_valid = %b, PID_error = %b, start_crc = %b, end_crc = %b, end_decode=%b",
				 dut.fsm.cs.name, dut.fsm.ns.name, s_out,
				 dut.PID_checked, dut.PID_valid,
				 PID_error, start_rc_crc, end_rc_crc, end_decode);
	
	pid = "11000011";  //correct PID
	pid = "1100001111110111011111011011010101111011011111010101110101111111010100111101101111000101";
	n = pid.len();
	rc_PIDerror <= 0;
	//pid = "1010111100001111";  //incorrect PID
	end_decode <= 0;
	start_decode <= 0;
	@(posedge clk);
	@(posedge clk);
	start_decode <= 1;
	in = pid.getc(0);
	s_in <= in.atoi();
	$display("s_in is %s", in);
	@(posedge clk);
	start_decode <= 0;
	for(int i = 1; i < n-1; i++) begin
		in = pid.getc(i);
		$display("s_in is %s", in);
		s_in <= in.atoi();
		@(posedge clk);
		end
	in = pid.getc(n-1);
	s_in <= in.atoi();
	$display("s_in is %s", in);
	@(posedge clk);
	end_decode <= 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	#2 $finish;
	end
endmodule : bs_decoder_test

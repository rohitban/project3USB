module rc_crc_test;
	logic clk, rst_n, s_in;
	logic start_rc_crc, end_rc_crc;
	logic rc_CRCerror, pkt_rec, pkt_status;
	logic CRC_error;
	logic [7:0] rc_hshake;
	logic [63:0] rc_data;

	rc_crc		dut(.*);

	initial begin
		rst_n = 0;
		rst_n <= 1;
		clk = 0;
		forever #5 clk = ~clk;
	end

	string data;
	int n;
	string in;

	initial begin
	$monitor($time, ,
				"cs(%s), ns(%s), count(%d) pkt_status(%b), CRC_error(%b), rc_hshake(%b), crc(%b),rec_crc(%b)", dut.fsm.cs.name, dut.fsm.ns.name, dut.count, pkt_status, CRC_error, rc_hshake, dut.crc16_val, dut.rc_crc16);
	
	//data = 1100_0011_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1101_0101_0000_0000_0000_0011_0010_0011
	//data = "1100001100000000000000000000000000000000000000000000000011010101000000000000001100100011"; //correct data
	//data = "1100001100000000000000000000000000000000000000000000000011010101000000000000001100100011"; //correct data
   //data =   "1101101111000101";
	data = "1100001111110111011111011011010101111011011111010101110101111111010100111101101111000101";
	n = data.len();
	
	pkt_rec = 0;
	end_rc_crc = 0;
	start_rc_crc = 0;
	@(posedge clk);
	start_rc_crc <= 1;
	in = data.getc(0);
	s_in <= in.atoi();
	$display("s_in is %s", in);
	@(posedge clk);
	start_rc_crc <= 0;

		for(int i = 1; i < n-1; i++) begin
			in = data.getc(i);
			$display("s_in is %s", in);
			s_in <= in.atoi();
			@(posedge clk);
		end
	
	in = data.getc(n-1);
	s_in <= in.atoi();
	$display("s_in is %s", in);
	@(posedge clk);
	end_rc_crc <= 1;
	@(posedge clk);
	pkt_rec <= 1;
	rc_CRCerror <= 1;
	@(posedge clk);
	@(posedge clk);
	#2 $finish;
	end

endmodule : rc_crc_test

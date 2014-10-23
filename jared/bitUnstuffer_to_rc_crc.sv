`define PROCESSING 1'b0
`define RECEIVED 1'b1


module rc_nrzi_test;
	/* rc_nrzi */
	logic clk, rst_n;
	logic s_in, start_rc_nrzi, end_rc_nrzi;
	logic start_unstuffer, end_unstuffer, s_out;
	/* bitUnstuffer */
	logic s_out_unstuff;
	logic start_decode, end_decode;
	/* bit stream decoder */
	logic start_rc_crc, end_rc_crc, PID_error, rc_PID_error, s_out_decoder;
	/*rc_crc*/
	logic rc_CRCerror, pkt_rec, pkt_status, CRC_error, rc_PIDerror;
	logic [7:0] rc_hshake;
	logic [63:0] rc_data;
	

//	rc_nrzi     nrzi(.*);

	bitUnstuffer   unstuff(.clk, .rst_n, .s_in(s_out), .start_unstuffer, .end_unstuffer, 
								  .s_out(s_out_unstuff),.start_decode, .end_decode);
	
	bs_decoder      bsdecode(.clk, .rst_n, .start_decode, .end_decode, .s_in(s_out_unstuff), 
									 .start_rc_crc, .end_rc_crc, .PID_error, .rc_PIDerror, .s_out(s_out_decoder));
	
	rc_crc              crc(.clk, .rst_n, .s_in(s_out_decoder), .start_rc_crc, .end_rc_crc, .rc_CRCerror, .pkt_rec, .pkt_status, .CRC_error, .rc_hshake, .rc_data);

	initial begin	
		rst_n = 0;
		rst_n <= 1;
		clk = 0;
		forever #5 clk = ~clk;
	end

	int n;
	string in;
	string data;

	initial begin
	$monitor($time, , 
				"bitunstuff_out = %b, unstuff_cs(%s), unstuff_ns(%s), crc_cs(%s), crc_ns(%s), bs_decode_cs(%s), bs_decode_ns(%s), PIDchecked(%b) PIDvalid(%b) rc_shake=%b, pkt_status =%b ",
				 s_out, unstuff.fsm.cs.name, unstuff.fsm.ns.name, crc.fsm.cs.name, crc.fsm.ns.name,bsdecode.fsm.cs.name, bsdecode.fsm.ns.name, bsdecode.PID_checked, bsdecode.PID_valid,rc_hshake, pkt_status );
	
	end_unstuffer <= 0;
   data = "11000011111101110111110110110101011110110111110101011101011111101010100111101101111000101";
   rc_PIDerror <= 0;
	//Unstuffed //data = "1100001111110111011111011011010101111011011111010101110101111111010100111101101111000101";
	n = data.len();
	assert(n == 89);
	start_unstuffer <= 1;
	in = data.getc(0);
	s_out <= in.atoi();  //s_out is s_in to bitUnstuffer
	@(posedge clk);
	
	
	
	start_unstuffer <= 0;
	for(int i = 0; i < n-1; i++) begin
		in = data.getc(i);
		s_out <= in.atoi();
		@(posedge clk);
		end
	
	in = data.getc(n-1);
	s_out <= in.atoi();  //s_out is s_in to bitUnstuffer
	end_unstuffer <= 1;
	@(posedge clk);
	end_unstuffer <= 0;
	wait(pkt_status == `RECEIVED);
	@(posedge clk);
	assert(rc_hshake == 8'b11000011);
   assert(rc_data == 64'b1111011101111101101101010111101101111101010111010111111101010011);
	@(posedge clk);
	@(posedge clk);
	pkt_rec <= 1;
	@(posedge clk);
	pkt_rec <= 0;
	@(posedge clk);
	#3 $finish;
	
	
	end
	
endmodule : rc_nrzi_test


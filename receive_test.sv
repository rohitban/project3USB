`define PROCESSING 1'b0
`define RECEIVED 1'b1

`define J 2'b10
`define K 2'b01
`define X 2'b00



module rc_test;
	/* rc_dpdm*/
	logic dpdm_out, receive_data, receive_hshake;
	logic EOP_error, got_sync;
	logic [1:0] bus_in;
	logic enable;
	/* decode_nrzi */
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
	logic nrzi_en, nrzi_l;
	logic [88:0] Q;
	logic abort;
	logic rc_dpdm_wait, rc_nrzi_wait, bitUnstuff_wait, bs_decoder_wait;
	logic rc_crc_wait;

	rc_dpdm			dpdm(.clk, .rst_n, .s_out(dpdm_out), 
							  .start_rc_nrzi, .end_rc_nrzi,
							  .receive_data, .receive_hshake,
							  .abort, .EOP_error, .got_sync, 
							  .bus_in, .enable,
							  .rc_dpdm_wait);
		
	
	decode_nrzi     nrzi(.clk, .rst_n, .s_in(dpdm_out), .s_out, 
								.start_unstuffer, .end_unstuffer, 
								.start_rc_nrzi, .end_rc_nrzi,
								.abort, .rc_nrzi_wait);

	sipo_register  #(89) nrziSIPO(.clk, .en(nrzi_en), .left(1'b1), .Q, 
											.s_in(s_out));

	bitUnstuffer   unstuff(.clk, .rst_n, .s_in(s_out), .start_unstuffer, .end_unstuffer, 
								  .s_out(s_out_unstuff),.start_decode, .end_decode,
								  .abort, .bitUnstuff_wait);
	
	bs_decoder      bsdecode(.clk, .rst_n, .start_decode, .end_decode, .s_in(s_out_unstuff), 
									 .start_rc_crc, .end_rc_crc, .PID_error, .rc_PIDerror, .s_out(s_out_decoder), .abort, .bs_decoder_wait);
	
	rc_crc             rccrc(.clk, .rst_n, .s_in(s_out_decoder), .start_rc_crc, .end_rc_crc, .rc_CRCerror, .pkt_rec, .pkt_status, .CRC_error, .rc_hshake, .rc_data, .rc_crc_wait, .abort);

	initial begin	
		rst_n = 0;
		rst_n <= 1;
		clk = 0;
		forever #5 clk = ~clk;
	end

	int n;
	string in;
	string data;
	string sync;

	initial begin
	$monitor($time, , 
				"crc_cs(%s), crc_ns(%s), bsdecode_cs(%s), bsdecode_ns(%s), PIDchecked(%b) PIDvalid(%b) pid(%b)  cpid(%b) inv_eq(%b) rc_shake=%b, pkt_status =%b crc_val %b , crc_rec %b pkt_status %b \n \ ",
				 rccrc.fsm.cs.name, rccrc.fsm.ns.name, bsdecode.fsm.cs.name, bsdecode.fsm.ns.name, bsdecode.PID_checked, bsdecode.PID_valid, bsdecode.pid.pid, bsdecode.pid.cpid, bsdecode.pid.inv_eq, rc_hshake, pkt_status,  rccrc.crc16_val, rccrc.rc_crc16, pkt_status);

	rc_PIDerror <= 0;
	sync = "KJKJKJKK";
	//data = "JJKJJKKJ"; //wrong handshake
	//data = "KKJKJKKKKKKKJJJJKKKKKKJJJKKKJJKKJJJJJKKKJJJJJJKKJJKKKKJJKKKKKKKJJKKJJKJJJJJKKKJJJJJKJKKJJ";
	//data = "JJKJJKKK"; //ACK HSHAKE
	data = "JJKKKJJK"; //NAK HSHAKE
	//data = "JJKKJJJJJKKK"; //wrong handhsake
	n = data.len();
	bus_in <= `X;
	enable <= 0;
	receive_data <= 0;
	receive_hshake <= 0;
	@(posedge clk);
	receive_hshake <= 1;
	//receive_data <= 1;
	abort <= 0;	
	//assert(n == 89);
	
	for(int i = 0; i < sync.len(); i++) begin
			in = sync[i];
			if(in == "K")
				bus_in <= `K;
			else if(in == "J")
				bus_in <= `J;
			else //in == "X"
				bus_in <= `X;
			@(posedge clk);
		end
	$display("SYNC has been FOUND!");

	if(data[0] == "K")
		bus_in <= `K;
	else if(data[0] == "J")
		bus_in <= `J;
	else if(data[0] == "X")
		bus_in <= `X;
	
	nrzi_en <= 1;
	
	@(posedge clk);
		for(int j = 1; j < n; j++) begin
			in = data[j];
			if(in == "K")
				bus_in <= `K;
			else if(in == "J")
				bus_in <= `J;
			else //in == "X"
				bus_in <= `X;
			@(posedge clk);
		end
	
	nrzi_en <= 0;
	bus_in <= `X;	
	@(posedge clk);
   
	//assert(Q == 8'b01001011);
	//assert(Q == 89'b11000011111101110111110110110101011110110111110101011101011111101010100111101101111000101);
	
	wait(end_rc_nrzi);
	$strobe("After entire hshake has been given currently in (%s)",
				dpdm.cs.name);
	bus_in <= `X;
	@(posedge clk);
	bus_in <= `J;
	@(posedge clk);
	$strobe("At the end of the simulation state is(%s)", dpdm.cs.name);

	@(posedge clk);
	
		rc_PID_error <= 1;
	@(posedge clk);
	wait(pkt_status == `RECEIVED);
	@(posedge clk);
	//assert(rc_hshake == 8'b01001011);
	//assert(rc_hshake == 8'b11000011);
   //assert(rc_data == 64'b1111011101111101101101010111101101111101010111010111111101010011);
	@(posedge clk);
	@(posedge clk);
	pkt_rec <= 1;
	@(posedge clk);
	pkt_rec <= 0;
	@(posedge clk);
	#3 $finish;
	end
	
endmodule : rc_test


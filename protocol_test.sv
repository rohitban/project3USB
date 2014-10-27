/* PID values */
`define NAK_PID 8'b01011010
`define ACK_PID 8'b01001011

/* outputs to bit stream encoder */
`define NONE 2'b00
`define TOKEN 2'b01
`define DATA 2'b11
`define HSHAKE 2'b10

/* inputs from read/write FSM */
`define NONE_MSG 3'b000
`define IN_TOK 3'b001
`define OUT_TOK 3'b010
`define OUT_DATA 3'b011
`define IN_DATA 3'b100

/* constant Values */
`define IN_TOK_VAL 19'b1001_0110_10100000_001
`define OUT_TOK_VAL 19'b1000_0111_10100000_001

/* pkt_status values */
`define RECEIVED 1'b1
`define PROCESSING 1'b0


`define J 2'b10
`define K 2'b01
`define X 2'b00



module protocol_test;
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


	logic rst_L;	
	logic [2:0]  msg_type;
//	logic [15:0] RWmemPage;
//	logic [63:0] RW_data_write, RW_data_read, rw_din, rw_dout;
//	logic start_write, start_read, read_success, write_success;
	logic protocol_free, timeout;
//	logic rwFSM_done;
  /**** read/wrtie FSM ***/
 /*  rwFSM        rwfsm(.clk, .rst_L, 
							 .RWmemPage, .RW_data_write,
							 .start_write, .start_read,
							 .read_success, .write_success,
							 .RW_data_read, .rwFSM_done,
							 .protocol_free, .timeout, .rw_din,
							 .msg_type, .rw_dout);
*/
  /**** ProtocolFSM *****/	
	logic rc_EOPerror;
	logic free_inbound;
	logic [1:0] pkt_type;
	logic [63:0] protocol_din, protocol_dout;
	logic [18:0] token;
	logic [7:0] hshake;
	logic [71:0] data;
	logic pkt_sent;
	assign rst_L = rst_n;

	protocolFSM    pfsm(.clk, .rst_L(rst_n), .msg_type, .protocol_din,
							  .protocol_free, .timeout, .protocol_dout,
							  .pkt_sent, .free_inbound, 
							  .pkt_type, .token, .data, .hshake, 
							  .pkt_status, .PID_error, .CRC_error, 
							  .device_data(rc_data), .device_hshake(rc_hshake),
							  .pkt_rec, .rc_CRCerror, .rc_PIDerror,
							  .got_sync, .EOP_error, .rc_EOPerror,
							  .receive_data, .receive_hshake, 
							  .abort, .rc_dpdm_wait, .rc_nrzi_wait,
							  .bitUnstuff_wait, .bs_decoder_wait,
							  .rc_crc_wait);


  logic [1:0] pkt_in;
  logic endr;
  logic bs_out;
  logic sent_pkt;
  logic bsEncode_en;
  logic [79:0] result_bsEncode;

  bs_encoder bs(.clk,.rst_n(rst_L),.pkt_type,
                .data,.token,.hshake,
                .free_inbound, .sent_pkt,
                .pkt_in,.endr, .pkt_sent,
                .s_out(bs_out));
  
  sipo_register #(80)   bssipo(.clk, .Q(result_bsEncode), .en(bsEncode_en),
							       .left(1'b1), .s_in(bs_out));


  /**************CRC**************/
  //Inputs
  logic pause;

  //Outputs
  logic start_b, endb;
  logic c_out;
  logic [95:0] result_crc;
  logic crc_en;

  crc crc_ms(.clk,.rst_n(rst_L),.s_in(bs_out),
             .endr,.pkt_in,.pause,.start_b,.endb,
             .s_out(c_out));

	sipo_register #(96)   crcsipo(.clk, .Q(result_crc), .en(crc_en),
							       .left(1'b1), .s_in(c_out));

  /***********Bit stuffer************/

  //Outputs
  logic start_nrzi,done;
  logic s_out_stuff;
  logic unstuff_en;
  logic [95:0] result_pkt;

  bit_stuff bit_st(.clk,.rst_n(rst_L),.s_in(c_out),
                   .start(start_b),.endb,.done,.pause,
                   .start_nrzi,
                   .s_out(s_out_stuff));

	sipo_register #(96)  bstuff(.clk, .Q(result_pkt), 
								 .en(unstuff_en), .left(1'b1), .s_in(s_out_stuff));

  /************NRZI******************/
  //Outputs
  logic start_dpdm, eop, s_out_nrzi;

  nrzi nrzi_inst(.clk,.rst_n(rst_L),.start_dpdm,
                 .s_in(s_out_stuff),.start_nrzi,
                 .done,.eop,
                 .s_out(s_out_nrzi));

  /************DPDM*******************/
	
	logic [1:0] host_out;
	
  dpdm dpdm_inst(.clk,.rst_n(rst_L),.s_in(s_out_nrzi),
                 .eop,.start_dpdm,.sent_pkt,
                 .enable,.host_out);



/**************RECEIVING END****************/


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
	string rcdata;
	string sync;

	initial begin
	$monitor($time, ,
			/*	"\n \ msg_type(%b) 100:IN_DATA 011:OUT_DATA 001:IN_TOK 010:OUT_TOK \n \ protocol_cs(%s)  protocol_ns(%s) \n \ ********************************************** \n \ *****************RECEIVING******************** \n \ ********************************************** \n \ got_sync(%b) \n \ receive_data(%b), receive_shake(%b) \n \ ABORT!!!(%b) when PID_error(%b) CRC_error(%b) EOP_error(%b) \n \ rc_PID_error(%b) rc_CRC_error(%b) rc_EOP_error(%b) \n \ ----------------- \n \ rc_dpdm_wait(%b), rc_nrzi_wait(%b), bitUnstuff_wait(%b), bs_deocer_wait(%b), rc_crc_wait(%b) \n \ ----------------- \n \ CRC_cs(%s), CRC_ns(%s) startRCcrc(%b), endRCcrc(%b) \n \ crc_computed = %b, crc_received = %b \n \ .----------------- \n \ bsdecode_cs(%s), bsdecode_ns(%s), start_decoder(%b), end_decoder(%b) \n \ PID_checked(%b), PIDvalid(%b), pid(%b), cpid(%b) is_pid(%b) inv_eq(%b) \n \ ----------------- \n \ unstuff_cs(%s), unstuff_ns(%s), unstuff_start(%b), unstuff_end(%b)  \n \ nrzi_cs(%s), nrzi_ns(%s), nrzi_start(%b), nrzi_end(%b) \n \ -------------------- \n \ pkt_status %b pkt_rec = %b \n \ rc_hshake(%b) \n \ rc_data(%b) \n \ ============================================================================ \n \ ============================================================================ */ "\n \ protocol_cs(%s)  protocol_ns(%s) \n \ ********************************************** \n \ ******************SENDING********************* \n \ ********************************************** \n \ pkt_type = (%b) \n \ hshake (%b) \n \ token (%b) \n \ data (%b) \n \ ----------------- \n \ pkt_sent(%b) \n \ result_bsEncode(%b)\n \ result_crc (%b) \n \ crc_fifo (%b) getPtr(%d) putPtr(%d) \n \ pause(%b) \n \ result_pkt (%b) \n \ --------------- \n \ bsEncode_cs(%s)  bsEncode_ns(%s) \n \ bs_data (%b) \n \ bs_token (%b) \n \ bs_hshake (%b) \n \ crc_cs(%s)  crc_ns(%s)  pkt_in(%b)  endr(%b) \n \ bitStuff_cs(%s)  bitStuff_ns(%s)  start_b(%b)  endb(%b) \n \ nrzi_cs(%s)  nrzi_ns(%s)  start_nrzi(%b)  end_nrzi(%b) \n \ dpdm_cs(%s)  dpdm_ns(%s)  start_dpdm(%b)  eop(%b) \n \ ============================================================================ \n \ ============================================================================ \n \ ",
/*				 msg_type,
				 pfsm.cs.name, pfsm.ns.name, 
				 got_sync,
				 receive_data, receive_hshake, 
				 abort, PID_error, CRC_error, EOP_error,
				 rc_PIDerror, rc_CRCerror, rc_EOPerror,
				 rc_dpdm_wait, rc_nrzi_wait, bitUnstuff_wait, bs_decoder_wait, rc_crc_wait,
				 rccrc.fsm.cs.name, rccrc.fsm.ns.name, start_rc_crc, end_rc_crc,
				 rccrc.crc16_val, rccrc.rc_crc16,
				 bsdecode.fsm.cs.name, bsdecode.fsm.ns.name, start_decode, end_decode,
				 bsdecode.PID_checked, bsdecode.PID_valid, bsdecode.pid.pid, bsdecode.pid.cpid, 
				 bsdecode.pid.is_pid, bsdecode.pid.inv_eq,
				 unstuff.fsm.cs.name, unstuff.fsm.ns.name, start_unstuffer, end_unstuffer, 
				 nrzi.nz_fsm.cs.name, nrzi.nz_fsm.ns.name, start_rc_nrzi, end_rc_nrzi, 
				 pkt_status, pkt_rec,
				 rc_hshake,
				 rc_data,*/
				 pfsm.cs.name, pfsm.ns.name,
				 pkt_type, hshake, token, data,
				 pkt_sent,
				 result_bsEncode,
				 result_crc,
				 crc_ms.q.Q, crc_ms.q.getPtr, crc_ms.q.putPtr,
				 pause,
				 result_pkt,
				 bs.fsm.cs.name, bs.fsm.ns.name,
				 bs.data_out,
				 bs.token_out,
				 bs.hshake_out,
				 crc_ms.ctrl.crc_cs.name, crc_ms.ctrl.crc_ns.name, pkt_in, endr,
				 bit_st.fsm.bs_cs.name, bit_st.fsm.bs_ns.name, start_b, endb, 
				 nrzi_inst.fsm.cs.name, nrzi_inst.fsm.ns.name, start_nrzi, done, 
				 dpdm_inst.dpdm_cs.name, dpdm_inst.dpdm_ns.name, start_dpdm, eop);
	
	
	//RWmemPage <= 16'hab00;
	//RW
	//wait(protocol_free);
	//sync = "KJKJKJKK";
	bsEncode_en <= 1;
	crc_en <= 1;
	unstuff_en <= 1;
	msg_type <= `OUT_DATA; 
	protocol_din <= 64'b1111011101111101101101010111101101111101010111010111111101010011;
	@(posedge clk);
	
	wait(endr);
	bsEncode_en <= 0;
	@(posedge clk);


	wait(done);
	crc_en <= 0;
	unstuff_en<= 0;
	@(posedge clk);
	$display("Assertions Passed");
	$display("%b", result_crc);
	$display("%b", 96'b000000011100001111110111011111011011010101111011011111010101110101111111010100111101101111000101);
	assert(result_crc == 96'b000000011100001111110111011111011011010101111011011111010101110101111111010100111101101111000101);
	assert(result_pkt == 96'b000000011100001111110111011111011011010101111011011111010101110101111111010100111101101111000101);
	wait(sent_pkt);
	@(posedge clk);
		
	#5 $finish;
	//rcdata = "JJKJJKKJ"; //wrong handshake
	//rcdata = "KKJKJKKKKKKKJJJJKKKKKKJJJKKKJJKKJJJJJKKKJJJJJJKKJJKKKKJJKKKKKKKJJKKJJKJJJJJKKKJJJJJKJKKJJ";
	//rcdata = "JJKJJKKK"; //ACK HSHAKE
	//rcdata = "JJKKKJJK"; //NAK HSHAKE
	//rcdata = "JJKKJJJJJKKK"; //wrong handhsake
/*	n = rcdata.len();
	bus_in <= `X;
	@(posedge clk);
	//receive_data <= 1;
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

	if(rcdata[0] == "K")
		bus_in <= `K;
	else if(rcdata[0] == "J")
		bus_in <= `J;
	else if(rcdata[0] == "X")
		bus_in <= `X;
//	$display("data is %s", rcdata[0]);	
	nrzi_en <= 1;
	
	@(posedge clk);
		for(int j = 1; j < n; j++) begin
			in = rcdata[j];
			if(in == "K")
				bus_in <= `K;
			else if(in == "J")
				bus_in <= `J;
			else //in == "X"
				bus_in <= `X;
	//$display("data is %s", in);	
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
	
	
	wait(pkt_rec == 1);
	@(posedge clk);
	//assert(rc_hshake == 8'b01001011);
	assert(rc_hshake == 8'b11000011);
   assert(rc_data == 64'b1111011101111101101101010111101101111101010111010111111101010011);
	@(posedge clk);
	
	wait(sent_pkt);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	#3 $finish;
*/
	end
	
endmodule : protocol_test


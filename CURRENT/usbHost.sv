

///////////////////////////////////////

// Write your usb host here.  Do not modify the port list.
module usbHost
  (input logic clk, rst_L, 
  usbWires wires);

  //Deal with the wires
  logic enable;
  logic [1:0] host_out;
  logic [1:0] bus_in;

  assign wires.DP = enable?host_out[1]:1'bz;
  assign wires.DM = enable?host_out[0]:1'bz;

//  assign bus_in = wires;
  /***************************************/

  // usbHost starts here!!

	logic [2:0]  msg_type;
	logic [15:0] RWmemPage;
	logic [63:0] RW_data_write, RW_data_read, rw_din, rw_dout;
	logic start_write, start_read, read_success, write_success;
	logic rwFSM_done, protocol_free, timeout;

  /**** read/wrtie FSM ***/
   rwFSM        rwfsm(.clk, .rst_L, 
							 .RWmemPage, .RW_data_write,
							 .start_write, .start_read,
							 .read_success, .write_success,
							 .RW_data_read, .rwFSM_done,
							 .protocol_free, .timeout, .rw_din,
							 .msg_type, .rw_dout);

  /**** ProtocolFSM *****/
	logic receive_data, receive_hshake;
	logic abort, got_sync;
	logic [1:0] pkt_type;
	logic [63:0] protocol_dout, protocol_din, rc_data;
	logic free_inbound, pkt_sent;
	logic [18:0] token;
	logic [7:0] hshake, rc_hshake;
	logic [71:0] data;
	logic pkt_status;
	logic PID_error, CRC_error, EOP_error;
	logic pkt_rec, rc_CRCerror, rc_PIDerror, rc_EOPerror;
	logic rc_dpdm_wait, rc_nrzi_wait, bitUnstuff_wait, bs_decoder_wait;
	logic rc_crc_wait;

	protocolFSM    pfsm(.clk, .rst_L, .msg_type, .protocol_din,
							  .protocol_free, .timeout, .protocol_dout,
							  .free_inbound, .pkt_sent, 
							  .pkt_type, .token, .data, .hshake, 
							  .pkt_status, .PID_error, .CRC_error, 
							  .device_data(rc_data), .device_hshake(rc_hshake),
							  .pkt_rec, .rc_CRCerror, .rc_PIDerror,
							  .got_sync, .EOP_error, .rc_EOPerror,
							  .receive_data, .receive_hshake, 
							  .abort, .rc_dpdm_wait, .rc_nrzi_wait,
							  .bitUnstuff_wait, .bs_decoder_wait,
							  .rc_crc_wait);
	
  /****Bit stream encoder****/
  //Outputs
  logic [1:0] pkt_in;
  logic endr;
  logic s_out;
  logic sent_pkt;

  bs_encoder bs(.clk,.rst_n(rst_L),.pkt_type,
                .data,.token,.hshake,
                .free_inbound, .sent_pkt,
                .pkt_sent,.pkt_in,.endr,
                .s_out);
  
  logic start_decode, end_decode, unstuff_out, bsdecoder_out;
  logic start_rc_crc, end_rc_crc;
  
  bs_decoder bsd(.clk, .rst_n(rst_L), .abort,
  					  .start_decode, .end_decode,
					  .s_in(unstuff_out), .s_out(bsdecoder_out),
					  .start_rc_crc, .end_rc_crc, .PID_error,
					  .bs_decoder_wait, .rc_PIDerror);

  /*******************************/
  /**************CRC**************/
  //Inputs
  logic pause;

  //Outputs
  logic start_b, endb;
  logic c_out;

  crc crc_ms(.clk,.rst_n(rst_L),.s_in(s_out),
             .endr,.pkt_in,.pause,.start_b,.endb,
             .s_out(c_out));


  rc_crc   rcrc(.clk, .rst_n(rst_L), .abort, .s_in(bsdecoder_out),
  					 .start_rc_crc, .end_rc_crc, .rc_CRCerror, .pkt_rec,
					 .pkt_status, .CRC_error, .rc_hshake, .rc_data, 
					 .rc_crc_wait);
	
  /***********Bit stuffer************/

  //Outputs
  logic start_nrzi,done;
  logic s_out_stuff;

  logic start_unstuffer, end_unstuffer;
  logic rnrzi_out;

  bit_stuff bit_st(.clk,.rst_n(rst_L),.s_in(c_out),
                   .start(start_b),.endb,.done,.pause,
                   .start_nrzi,
                   .s_out(s_out_stuff));

   
  bitUnstuffer  bit_unst(.clk, .rst_n(rst_L), .abort, .bitUnstuff_wait,
  								 .start_unstuffer, .end_unstuffer, 
								 .start_decode, .end_decode,
								 .s_in(rnrzi_out), .s_out(unstuff_out));

  /**********************************/

  /************NRZI******************/
  //Outputs
  logic start_dpdm, eop, s_out_nrzi;
  logic start_rc_nrzi, end_rc_nrzi;
  logic rdpdm_out;

  nrzi nrzi_inst(.clk,.rst_n(rst_L),.start_dpdm,
                 .s_in(s_out_stuff),.start_nrzi,
                 .done,.eop,
                 .s_out(s_out_nrzi));

  decode_nrzi   rnrzi(.clk, .rst_n(rst_L), .start_rc_nrzi,
  							 .end_rc_nrzi, .abort, 
							 .start_unstuffer, .end_unstuffer, 
							 .rc_nrzi_wait,
							 .s_in(rdpdm_out), .s_out(rnrzi_out));
  /***********************************/

  /************DPDM*******************/

  dpdm dpdm_inst(.clk,.rst_n(rst_L),.s_in(s_out_nrzi),
                 .eop,.start_dpdm,.sent_pkt,
                 .enable,.host_out);

  rc_dpdm  rc_dpdm_inst(.clk, .rst_n(rst_L), .s_out(rdpdm_out),
  								.start_rc_nrzi, .end_rc_nrzi, 
								.receive_data, .receive_hshake, 
								.abort, .EOP_error, .got_sync, .rc_dpdm_wait,
								.bus_in, .enable);

  /***********************************/
  
  /***************************************/






  /* Tasks needed to be finished to run testbenches */
	logic [7:0] pid;
	logic [63:0] payload;
	logic [63:0] y;
	logic [63:0] RWdata_write;
  task prelabRequest
  // sends an OUT packet with ADDR=5 and ENDP=4
  // packet should have SYNC and EOP too
  (input bit [7:0] data);
	
//	wait(free_inbound);
//	pkt_type <= `TOKEN;
//	pid = 8'b11000011;
//	payload = 64'hcafebabedeadbeef;
//	y = {<<{payload}};
//	data <= {pid,y};
	
//  token <= 19'b1001_0110_1010000_0010;
//	@(posedge clk);

//	wait(free_inbound);
//    @(posedge clk);
  endtask: prelabRequest

  task readData
  // host sends memPage to thumb drive and then gets data back from it
  // then returns data and status to the caller
  (input  bit [15:0]  memPage_read, // Page to write
   output bit [63:0] data_read, // array of bytes to write
   output bit        success);
	
	start_read <= 0;
	@(posedge clk);
	RWmemPage <= memPage_read;
	start_read <= 1;
	@(posedge clk);
	start_read <= 0;
	@(posedge clk);

	wait(rwFSM_done);
	
	start_read <= 0;
	data_read <= RW_data_read;
	success <= read_success;
	@(posedge clk);

  endtask: readData

  task writeData
  // Host sends memPage to thumb drive and then sends data
  // then returns status to the caller
  (input  bit [15:0]  memPage_write, // Page to write
   input  bit [63:0] data_write, // array of bytes to write
   output bit        success);

//	start_write <= 0;
//	@(posedge clk);
	RWmemPage <= memPage_write;
	RWdata_write <= data_write;
	start_write <= 1;
	@(posedge clk);
	start_write <= 0;
	@(posedge clk);

	wait(rwFSM_done);
	
	start_write <= 0;
	success <= write_success;
	@(posedge clk);

  endtask: writeData


endmodule: usbHost

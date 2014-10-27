

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

  assign bus_in[1] = wires.DP;
  assign bus_in[0] = wires.DM;
  /***************************************/

  // usbHost starts here!!

  /****Bit stream encoder****/
  //Inputs
  logic [1:0]  pkt_type;
  logic [71:0] data_input;
  logic [18:0] token;
  logic [7:0]  hshake;
  logic        sent_pkt;

  //Outputs
  logic free_inbound;
  logic [1:0] pkt_in;
  logic endr;
  logic s_out;

  bs_encoder bs(.clk,.rst_n(rst_L),.pkt_type,
                .data(data_input),.token,.hshake,
                .free_inbound,
                .sent_pkt,.pkt_in,.endr,
                .s_out);
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

  /***********Bit stuffer************/

  //Outputs
  logic start_nrzi,done;
  logic s_out_stuff;

  bit_stuff bit_st(.clk,.rst_n(rst_L),.s_in(c_out),
                   .start(start_b),.endb,.done,.pause,
                   .start_nrzi,
                   .s_out(s_out_stuff));

  /**********************************/

  /************NRZI******************/
  //Outputs
  logic start_dpdm, eop, s_out_nrzi;

  nrzi nrzi_inst(.clk,.rst_n(rst_L),.start_dpdm,
                 .s_in(s_out_stuff),.start_nrzi,
                 .done,.eop,
                 .s_out(s_out_nrzi));

  /***********************************/

  /************DPDM*******************/
  
  dpdm dpdm_inst(.clk,.rst_n(rst_L),.s_in(s_out_nrzi),
                 .eop,.start_dpdm,.sent_pkt,
                 .enable,.host_out);
  
  /***********************************/
  
  /***************************************/

  /* Tasks needed to be finished to run testbenches */

  task prelabRequest
  // sends an OUT packet with ADDR=5 and ENDP=4
  // packet should have SYNC and EOP too
  (input bit [7:0] data);
	
	wait(free_inbound);
	pkt_type <= `TOKEN;
	token <= 19'b1000_0111_1111111_0010;
    //token <= 19'b1001_0110_1111111_1111;
	@(posedge clk);
    

	wait(free_inbound);
    @(posedge clk);
  endtask: prelabRequest

  logic [63:0] y;

  task readData
  // host sends memPage to thumb drive and then gets data back from it
  // then returns data and status to the caller
  (input  bit [63:0] memPage,
  // input  bit [15:0]  mempage, // Page to write
   output bit [63:0] data, // array of bytes to write
   output bit        success);
    
    y = {<<{memPage}};
    wait(free_inbound);
    pkt_type <= `DATA;

    data_input <= {8'b11000011,y};
    @(posedge clk);
    $display("\nInput is PID %b and data %b(%h)\n\n",data_input[71:64],
                                       data_input[63:0],memPage);
    data_input <= 0;

    wait(free_inbound);
    @(posedge clk);

  endtask: readData

  task writeData
  // Host sends memPage to thumb drive and then sends data
  // then returns status to the caller
  (input  bit [15:0]  mempage, // Page to write
   input  bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: writeData


endmodule: usbHost

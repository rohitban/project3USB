// Write your usb host here.  Do not modify the port list.
module usbHost
  (input logic clk, rst_L, 
  usbWires wires);

  //Deal with the wires
  logic enable;
  logic [1:0] host_out;

  assign wires.DP = enable?host_out[1]:1'bz;
  assign wires.DM = enable?host_out[0]:1'bz;

  /***************************************/

  /* Tasks needed to be finished to run testbenches */

  task prelabRequest
  // sends an OUT packet with ADDR=5 and ENDP=4
  // packet should have SYNC and EOP too
  (input bit  [7:0] data);
    
  endtask: prelabRequest

  task readData
  // host sends memPage to thumb drive and then gets data back from it
  // then returns data and status to the caller
  (input  bit [15:0]  mempage, // Page to write
   output bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: readData

  task writeData
  // Host sends memPage to thumb drive and then sends data
  // then returns status to the caller
  (input  bit [15:0]  mempage, // Page to write
   input  bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: writeData

  // usbHost starts here!!

  /****Bit stream encoder****/
  //Inputs
  logic [1:0]  pkt_type;
  logic [87:0] data;
  logic [23:0] token;
  logic [7:0]  hshake;
  logic        pause;
  logic        sent_pkt;

  //Outputs
  logic pkt_received,free_inbound;
  logic start, endr;
  logic s_out;

  bs_encoder bs(.clk,.rst_n(rst_L),.pkt_type,
                .data,.token,.hshake,
                .pkt_received,.free_inbound,
                .pause,.sent_pkt,
                .start,.endr,
                .s_out);
  /*******************************/
  /***********Bit stuffer************/

  //Outputs
  logic start_nrzi,done;
  logic s_out_stuff;

  bit_stuff bit_st(.clk,.rst_n(rst_L),.s_in(s_out),
                   .start,.endr,.done,.pause,
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
  



  
  

endmodule: usbHost

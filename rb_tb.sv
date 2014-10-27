//Your testbench module
module test
  (output logic clk, rst_L);
    
  logic [63:0] data;
  logic [63:0] memPage;
  logic success; 
  //Set up clk, rst_L, and then call your usbHost.sv tasks here  
  initial begin
    clk = 0;
    rst_L = 0;
    rst_L <= #1 1;
    forever #2 clk = ~clk;
  end
  //Ex: host.prelabRequest(data);
  //    host.writeData(memPage, data, success);
  //    host.readData(memPage, data, success);  
  initial begin
    memPage <= 64'h3ffe;
    //memPage <= 64'hffff;
    data <= 0;
    success <= 0;
    @(posedge clk);
    @(posedge clk);
    //host.prelabRequest(data);
    host.readData(memPage,data,success);
    #150;
    $finish;
  end

endmodule

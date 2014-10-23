//Your testbench module
module test
  (output logic clk, rst_L);
	logic [15:0] memPage;
	logic [63:0] data;
	logic success;
  //Set up clk, rst_L, and then call your usbHost.sv tasks here  
	initial begin
		rst_L = 0;
		rst_L <= 1;
		clk = 0;
		forever #5 clk = ~clk;
	end
	
	initial begin
		success = 0;
		data = 64'hcafebabedeadbeef;
		memPage = 16'b0000_0011_0000_0011;
//	token <= 19'b1000_0111_1010000_0010;
		host.writeData(memPage, data, success);
  //Ex: host.prelabRequest(data);
  //    host.writeData(memPage, data, success);
  //    host.readData(memPage, data, success);  
    @(posedge clk);
		wait(success);
		@(posedge clk);
		#2 $finish;
	end

endmodule

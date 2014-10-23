`define TOKEN 2'b01

module unstuff_test;
	logic clk, rst_n;
	logic s_in, end_unstuffer;
	logic start_unstuffer;
	logic start_decode, end_decode, s_out;
	logic [31:0] Q;
	logic        en, left;

  bitUnstuffer 	 dut(.clk,.rst_n,
							  .s_in, .start_unstuffer,
							  .end_unstuffer, 
							  .s_out, .start_decode, .end_decode);
                     		
	sipo_register #(32) s1(.s_in(s_out), .Q, .en,.left,.clk);

  string in;
  string data;
  int n;

	initial begin
		clk = 0;
		rst_n = 0;
		rst_n <= #1 1;
		forever #5 clk = ~clk;
	end

	initial begin
        $monitor($stime, "  Q = %b",Q);

//        data = "0000000111000011111101110111110110110101011110110111110101011101011111101010100111101101111000101";
//        data = "0000_0001_1100_0011_
//								1111_0111_0111_1101_1011_0101_0111_1011_0111_1101_0101_1101_0111_111_0_1010_10011_
//								1101101111000101";
		data = "111111011100001100110111111000111";
		//should return 0000 0001 1100 0011 0011 0111 1110 0111
		end_unstuffer <= 0;
		n = data.len();
        
        en<=0;
        left<=0;
		start_unstuffer <= 0;
		@(posedge clk);
		start_unstuffer <= 1;
		@(posedge clk);
		start_unstuffer <= 0;

        for(int i = 0; i < 8; i++) begin
          in = data.getc(i);
          s_in <= in.atoi();
          @(posedge clk);
        end
		left <= 1;
		en <= 1;
		  for(int j = 8; j < n; j++) begin
		  	 in = data.getc(j);
			 s_in <= in.atoi();
			 @(posedge clk);
		  end
      end_unstuffer <= 1;

		@(posedge clk);
		end_unstuffer <= 0;
		if(dut.empty) begin
			left <= 0;
			en <= 0;
		assert(Q == 32'b1111_1101_1100_0011_0011_0111_1110_0111);
		end
		wait(dut.empty);
      @(posedge clk);
		//should return 0000 0001 1100 0011 0011 0111 1110 0111
      @(posedge clk);
      $display("Simulation completed");
		$finish;
	end



endmodule: unstuff_test

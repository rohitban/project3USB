`define pkt 00000000_00000000_00000000_00000000_00000000_00000000_1101_0101_0000_0000

module tb;
    logic crc16_out,crc16_rec;
    logic crc16_ready,crc16_done,crc16_start,s_in;
    logic clk, rst_n;
    logic [15:0] Q, crc16_val;
    logic en,left;

    crc16 crc16_inst(.*);

    sipo_register #(16) s1(.clk,.en,.left,.Q,.s_in(crc16_out));

    initial begin
        $monitor($stime, " crc16_out=%b,crc16_ready=%b,crc16_done=%b,s_in=%b,Q=%b",
                            crc16_out,crc16_ready,crc16_done,s_in,Q);
        clk = 0; 
        rst_n = 0;
        rst_n <= #1 1;
        forever #5 clk = ~clk;
    end
	

	string data;
	string in;
	int n;

	initial begin
	$monitor($time, ,
				"Q(%b), crc16_val = %b", Q, crc16_val);
	
	//data = 1100_0011_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1101_0101_0000_0000_0000_0011_0010_0011
	//data = "00000000000000000000000000000000000000000000000011010101000000000000001100100011"; //correct data
	//data = "11111110111010111101101011101101111010111010101111101111101011001101101111000101";
	data = "00000000000000000000000000000000000000000000000011010101000000001000001100100011"; //correct data
	n = data.len();
	
	crc16_start <= 1;
	in = data.getc(0);
	s_in <= in.atoi();
	$display("s_in is %s", in);
	@(posedge clk);
	crc16_start <= 0;

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
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	assert(crc16_val == (16'b0000001100100011));
	@(posedge clk);
	#2 $finish;
	end


/*
    initial begin
    crc16_start <= 1;
    en <= 0;
    left <= 0;
    crc16_rec <= 0;
    @(posedge clk);
    for(int i = 0; i <48;i++)begin
      s_in <= 0;
      @(posedge clk);
    end
    s_in <= 1;
    @(posedge clk);
		s_in <= 1;
		@(posedge clk);
		s_in <= 0;
		@(posedge clk);
		s_in <= 1;
		@(posedge clk);
		s_in <= 0;
		@(posedge clk);
		s_in <= 1;
		@(posedge clk);
		s_in <= 0;
		@(posedge clk);
		s_in <= 1;
		@(posedge clk);
    for(int i = 0; i<8;i++) begin
       s_in <= 0;
       @(posedge clk);
    end
    
    crc16_start <= 0;
    wait(crc16_ready);
    en <= 1;
    left <= 1;
    @(posedge clk);
    //1
    @(posedge clk);
    //10
    @(posedge clk);
    //100
    @(posedge clk);
    //1000
    @(posedge clk);
    //1000_0
		@(posedge clk);
		//1000_00
		@(posedge clk);
		//1000_000
		@(posedge clk);
		//1000_0000
		@(posedge clk);
		//1000_0000_0
		@(posedge clk);
		//1000_0000_00
		@(posedge clk);
		//1000_0000_000
		@(posedge clk);
		//1000_0000_0000
		@(posedge clk);
		//1000_0000_0000_0
		@(posedge clk);
		//1000_0000_0000_01
		@(posedge clk);
		//1000_0000_0000_010
		@(posedge clk);
		//1000_0000_0000_0101

    en <= 0;
    left <= 0;
    wait(crc16_done);
    crc16_rec <= 1;
    @(posedge clk);
    crc16_rec <= 0;
    @(posedge clk);
    $display("State is %s",crc16_inst.fsm_inst.cs.name); 
    $finish;
    end
*/

endmodule:tb

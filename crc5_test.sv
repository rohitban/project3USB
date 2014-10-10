`define pkt 1010000_0010

module tb;
    logic crc5_out;
    logic crc5_ready,crc5_done,crc5_start,s_in;
    logic clk, rst_n;

    crc5 crc5_inst(.*);

    initial begin
        $monitor($stime, " crc5_out=%b,crc5_ready=%b,crc5_done=%b,s_in=%b",
                            crc5_out,crc5_ready,crc5_done,s_in);
        clk = 0; 
        rst_n = 0;
        rst_n <= #1 1;
        forever #5 clk = ~clk;
    end

    initial begin
    crc5_start <= 1;
    @(posedge clk);
    s_in <= 1;
    @(posedge clk);
    s_in <= 0 ;
    @(posedge clk);
    s_in <= 1;
    @(posedge clk);
    for(int i = 0; i < 6; i = i+1)begin
      s_in <= 0;
      @(posedge clk);
    end
    s_in <= 1;
    @(posedge clk);
    s_in <= 0;
    @(posedge clk);

    wait(crc5_ready);
    wait(crc5_done);


        
    end


endmodule:tb

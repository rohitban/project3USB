`define pkt 0000_1000_111

module tb;
    logic crc5_out,crc5_rec;
    logic crc5_ready,crc5_done,crc5_start,s_in;
    logic clk, rst_n;
    logic [4:0] Q;
    logic en,left;

    crc5 crc5_inst(.*);

    sipo_register #(5) s1(.clk,.en,.left,.Q,.s_in(crc5_out));

    initial begin
        $monitor($stime, " crc5_out=%b,crc5_ready=%b,crc5_done=%b,s_in=%b,Q=%b",
                            crc5_out,crc5_ready,crc5_done,s_in,Q);
        clk = 0; 
        rst_n = 0;
        rst_n <= #1 1;
        forever #5 clk = ~clk;
    end

    initial begin
    crc5_start <= 1;
    en <= 0;
    left <= 0;
    crc5_rec <= 0;
    @(posedge clk);
    for(int i = 0; i <4;i++)begin
      s_in <= 0;
      @(posedge clk);
    end
    s_in <= 1;
    @(posedge clk);
    for(int i = 0; i<3;i++) begin
       s_in <= 0;
       @(posedge clk);
    end
    for(int i = 0; i<3;i++) begin
       s_in <= 1;
       @(posedge clk);
    end
    
    crc5_start <= 0;
    wait(crc5_ready);
    en <= 1;
    left <= 1;
    @(posedge clk);
    //0
    @(posedge clk);
    //01
    @(posedge clk);
    //011
    @(posedge clk);
    //0110
    @(posedge clk);
    //01100
    en <= 0;
    left <= 0;
    wait(crc5_done);
    crc5_rec <= 1;
    @(posedge clk);
    crc5_rec <= 0;
    @(posedge clk);
    $display("State is $s",crc5_inst.fsm_inst.cs.name); 
    $finish;
    end


endmodule:tb

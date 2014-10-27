`define TOKEN 2'b01

module bs_test;
	logic clk, rst_n;
	logic endr;
	logic [1:0] pkt_in;
	logic [97:0] Q;
	logic        en, left;

    //BS_ENCODER
    logic [1:0] pkt_type;
    logic [71:0] data;
    logic [18:0] token;
    logic [7:0] hshake;

    logic pkt_received;
    logic free_inbound;

    logic sent_pkt;//FOR dpdm

    logic bs_out;

    bs_encoder bs(.clk,.rst_n,.pkt_type,.data,.token,
                  .hshake,.free_inbound,
                  .sent_pkt,.pkt_in,.endr,.s_out(bs_out));

    //CRC MASTER
    logic pause;
    logic start_b, endb, crc_out;

    crc crc(.clk,.rst_n,.s_in(bs_out),.endr,.pkt_in,.pause,
            .start_b,.endb,.s_out(crc_out));

    //BITSTUFFER
    logic stuff_out;
    logic done,start_nrzi;

    bit_stuff stuffer(.clk,.rst_n,.s_in(crc_out),.s_out(stuff_out),
                      .done,.pause,.start(start_b),.endb,.start_nrzi);

    
	sipo_register #(98) s1(.s_in(stuff_out),.Q, .en,.left,.clk);
    

	initial begin
		clk = 0;
		rst_n = 0;
		rst_n <= #1 1;
		forever #5 clk = ~clk;
	end

	initial begin
        $monitor($stime, "  Q = %b",Q);
        data <= 0;
        hshake <= 0;
        token <= 0;
        pkt_type <= 0; 
        en <= 0;
        left <= 0;
		@(posedge clk);

        data <= {8'b1100_0011, 64'h7ffe_0000_0000_0000};
        pkt_type <= `DATA;

        @(posedge clk);
        data <= 0;
        pkt_type <= 0;
		@(posedge clk);
        $display("Encoder is in state (%s)",bs.fsm.cs.name);
        wait(start_nrzi);
        en <= 1;
        left <= 1;
        wait(endr);
        $display("Received endr");
        wait(crc.crc16_done);
        $display("CRC 16 has finished computation current in (%s)",
        crc.ctrl.crc_cs.name);
        @(posedge clk);
        $strobe("CRC has transitioned to state %s",crc.ctrl.crc_cs.name);
        wait(endb);
        $display("Received endb");
        wait(done);
        $display("Received done");
        en <= 0;
        left <= 0;
        sent_pkt <= 1;
        @(posedge clk);
        @(posedge clk);
        $display("Simulation completed with encoder state(%s)",
        bs.fsm.cs.name);
		$finish;
	end



endmodule: bs_test

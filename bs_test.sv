`define TOKEN 2'b01

module bs_test;
	logic clk, rst_n;
	logic endr;
	logic [1:0] pkt_in;
	logic pause, start_b, endb, s_out;
	logic [32:0] Q;
	logic        en, left;

    //Bit stuffer
    logic stuff_out, start_nrzi;
    logic done;
    
    //NRZI
    logic nrzi_out, start_dpdm;
    logic eop;

    //BS_ENCODER
    logic [1:0] pkt_type;
    logic [71:0] data;
    logic [18:0] token;
    logic [7:0] hshake;

    logic pkt_received;
    logic free_inbound;

    logic sent_pkt;//FOR dpdm

    logic bs_out;

    //DPDM
    logic [1:0] host_out;
    logic enable;

    dpdm       pe(.clk,.rst_n,.host_out,.enable,.sent_pkt,
                  .s_in(nrzi_out),.start_dpdm,.eop);

    bs_encoder bs(.clk,.rst_n,.pkt_type,.data,.token,
                  .hshake,.pkt_received,.free_inbound,
                  .sent_pkt,.pkt_in,.endr,.s_out(bs_out));

	crc     dut(.clk,.rst_n,.s_in(bs_out),.endr,.pkt_in,.pause,
    .start_b,.endb,.s_out);
    
    bit_stuff device(.clk,.rst_n,.s_in(s_out),
                     .start_nrzi,.done,.pause,
                     .s_out(stuff_out),.start(start_b),
                     .endb);

    nrzi mod(.clk,.rst_n,.s_in(stuff_out),.start_dpdm,
             .start_nrzi,.eop,.s_out(nrzi_out),.done);
    
	sipo_register #(33) s1(.s_in(nrzi_out), .Q, .en,.left,.clk);


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

        token <= 19'b10000001_1010000_0010; 
        pkt_type <= `TOKEN;

        @(posedge clk);
        token <= 0;
        pkt_type <= 0;
		@(posedge clk);

        $display("Encoder is in state (%s)",bs.fsm.cs.name);
        wait(start_b);
        $display("Start_b is (%b)",start_b);
        @(posedge clk);
        en <= 1;
        left <= 1;

        wait(dut.crc5_done);
        $display("Currently in state (%s)",dut.ctrl.crc_cs.name);
        wait(eop);
        en <= 0;
        left <= 0;
        wait(sent_pkt);
        @(posedge clk);
        @(posedge clk);
        $display("Simulation completed with crc at state (%s)",
                  dut.ctrl.crc_cs.name);
        $display("Simulation completed with crc5 at state(%s)",
                 dut.tcrc.fsm_inst.cs.name);
        $display("Simulation completed with bitstuffer at state(%s)",
                 device.stuff.bs_cs.name);
        $display("Simulation completed with nrzi at state(%s)",
                  mod.nz_fsm.nrzi_cs.name);
		$finish;
	end



endmodule: bs_test

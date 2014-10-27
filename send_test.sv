`define TOKEN 2'b01

module bs_test;
	logic clk, rst_n;
	logic endr;
	logic [1:0] pkt_in;
	logic pause, start_b, endb, s_out;
	logic [91:0] Q;
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

    logic free_inbound;

    logic sent_pkt;//FOR dpdm

    logic bs_out;

    //DPDM
    logic [1:0] host_out;
    logic enable;

    dpdm       pe(.clk,.rst_n,.host_out,.enable,.sent_pkt,
                  .s_in(nrzi_out),.start_dpdm,.eop);

    bs_encoder bs(.clk,.rst_n,.pkt_type,.data,.token,
                  .hshake,.free_inbound,
                  .sent_pkt,.pkt_in,.endr,.s_out(bs_out));

	crc     dut(.clk,.rst_n,.s_in(bs_out),.endr,.pkt_in,.pause,
    .start_b,.endb,.s_out);
    
    bit_stuff device(.clk,.rst_n,.s_in(s_out),
                     .start_nrzi,.done,.pause,
                     .s_out(stuff_out),.start(start_b),
                     .endb);

    nrzi mod(.clk,.rst_n,.s_in(stuff_out),.start_dpdm,
             .start_nrzi,.eop,.s_out(nrzi_out),.done);


    //Receiving dpdm
    logic dpdm_out;
    logic start_rc_nrzi,end_rc_nrzi;
    logic receive_data, receive_hshake;
    logic abort;
    logic EOP_error, got_sync;
    logic rc_dpdm_wait;
    logic [1:0] bus_in;

    tri0 [1:0] bus_wires;

        
    assign bus_wires = (enable)?host_out:2'bzz;

    rc_dpdm rc_d(.clk,.rst_n,.s_out(dpdm_out),.start_rc_nrzi,
                 .end_rc_nrzi,.receive_data,.receive_hshake,
                 .abort,.EOP_error,.got_sync,.bus_in(bus_wires),
                 .enable(1'b0),.rc_dpdm_wait);

    //Decode NRZI
    logic start_unstuffer, end_unstuffer;
    logic decode_out, rc_nrzi_wait;
    
    decode_nrzi decode(.clk,.rst_n,.start_unstuffer,.rc_nrzi_wait,
                       .end_unstuffer,.s_out(decode_out),.s_in(dpdm_out),
                       .start_rc_nrzi,.end_rc_nrzi,.abort);

    
    //Bit unstuffer
    logic bitUnstuff_wait;
    logic unstuff_out;
    logic start_decode,end_decode;

    bitUnstuffer us(.clk,.rst_n,.bitUnstuff_wait,.s_in(decode_out),
                    .start_unstuffer,.end_unstuffer,.s_out(unstuff_out),
                    .start_decode,.end_decode,.abort);
    
    //Bit stream decoder
    logic start_rc_crc, end_rc_crc;
    logic ds_out;
    logic PID_error, bs_decoder_wait;
    logic rc_PIDerror;

    bs_decoder bsd(.clk,.rst_n,.abort,.start_decode,.end_decode,
                   .s_in(unstuff_out),.s_out(ds_out),.start_rc_crc,.end_rc_crc,
                   .PID_error,.bs_decoder_wait,.rc_PIDerror);

    //RC CRC module
    logic rc_CRCerror;
    logic pkt_rec;
    logic 


   rc_crc rc_c(.clk,.rst_n,.abort,.s_in(ds_out),.start_rc_crc,
   .end_rc_crc,.rc_CRCerror,.pkt_rec


	sipo_register #(92) s1(.s_in(unstuff_out), .Q, .en,.left,.clk);

   
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

        abort <= 0;
        receive_data <= 1;
        receive_hshake <= 0;
		@(posedge clk);
        

        data <= {8'b1100_0011, 64'h7ffc_0000_0000_0000}; 
        pkt_type <= `DATA;

        @(posedge clk);
        token <= 0;
        pkt_type <= 0;
		@(posedge clk);

        $display("Encoder is in state (%s)",bs.fsm.cs.name);
        wait(got_sync);
        $display("I have the SYNC");
        $display("RC_dpdm is in state (%s)",rc_d.cs.name);
        wait(start_decode)
        $display("Begin decoding");
        @(posedge clk);
        en <= 1;
        left <= 1;

        wait(end_rc_nrzi);
        $display("All data sent to unstuffer");
        $display("Currently start_nrzi is (%b)",start_rc_nrzi);
        wait(end_decode);
        en <= 0;
        left <= 0;
        @(posedge clk);
        @(posedge clk);
        $display("RC dpdm is in state (%S)",rc_d.cs.name);
        $display("Simulation completed with crc at state (%s)",
                  dut.ctrl.crc_cs.name);
        $display("Simulation completed with crc5 at state(%s)",
                 dut.tcrc.fsm_inst.cs.name);
        $display("Simulation completed with bitstuffer at state(%s)",
                 device.fsm.bs_cs.name);
        $display("Simulation completed with nrzi at state(%s)",
                  mod.fsm.cs.name);
		$finish;
	end



endmodule: bs_test

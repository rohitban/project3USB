`define ACK_PID 4'b0010
`define NAK_PID 4'b1010
`define DATA_PID 4'b0011

module pid_checker
	(input  logic  clk, rst_n,
	 input  logic  start_decode, 
	 input  logic  s_in, 
	 input  logic  end_PID,
	 
	 output logic  PID_checked, PID_valid);
	
	
	logic [3:0] cpid, pid;
	logic [3:0] count;
	logic [7:0] dff_out, dff_in, sync_set, rd;
	logic inv_eq, is_pid, clr;
	logic incr;
	
	assign dff_in[7] = dff_out[6],
			 dff_in[6] = dff_out[5],
			 dff_in[5] = dff_out[4],
			 dff_in[4] = ~dff_out[3],
			 dff_in[3] = dff_out[2],
			 dff_in[2] = dff_out[1],
			 dff_in[1] = dff_out[0],
			 dff_in[0] = s_in;
	
	assign cpid = dff_out[7:4];
	assign pid  = dff_out[3:0];

	generate 
		for(genvar i = 0; i < 8; i++) 
			
			gen_dff	#(i)	dff_inst(.clk, .rst_n, .sync_set(sync_set[i]),  .clr,
											.d(dff_in[i]), .q(dff_out[i]), .rd(rd[i]));

	endgenerate

	assign inv_eq = (cpid == pid);
	assign is_pid = ((pid == `NAK_PID) || 
						  (pid == `ACK_PID) ||
						  (pid == `DATA_PID));

	counter 	#(4)  cnt(.count, .clr, .en(incr), .clk, .rst_n);

	pidFSM						fsm(.*);	

endmodule : pid_checker


module pidFSM
	(input  logic  clk, rst_n,
	 input  logic  start_decode,
	 input  logic  [3:0] count,

	 input  logic  inv_eq, is_pid,
	 input  logic  end_PID,

	 output logic  PID_checked, PID_valid,
	 output logic  [7:0] rd, sync_set,
	 output logic  incr,
	 output logic  clr);


	 enum logic [1:0] {WAIT, CHECK, VERIFIED, ERROR} cs, ns;

	 always_ff@(posedge clk, negedge rst_n)
	 	if(~rst_n)
			cs <= WAIT;
		else
			cs <= ns;

	 always_comb begin
	 PID_checked = 0;
	 PID_valid = 0;
	 rd = 8'b0;
	 sync_set = 8'b0;
	 incr = 0;
	 clr = 0;
	 case(cs)
	 WAIT:
	 begin
	 	ns = (start_decode) ? CHECK : WAIT;
		rd = (start_decode) ? 8'hff : 8'h0;
		incr = (start_decode) ? 1 : 0;
	 end
	 CHECK: 
	 begin
	 	if(count <= 4'd8)
			begin
			incr = 1;
			rd = 8'hff;
			end
		else
			begin
			if(inv_eq && is_pid)
				begin
				ns = VERIFIED;
				PID_checked = 1;
				PID_valid = 1;
				end
			else
				begin
				ns = ERROR;
				PID_checked = 1;
				PID_valid = 0;
				end
			end
	 end
	 VERIFIED:
	 begin
	 PID_checked = 1;
	 PID_valid = 1;
		if(end_PID)
			begin
			ns = WAIT;
			clr = 1;
			end
		else
			begin
			ns = VERIFIED;
			end
	 end
	 ERROR:
	 begin
		if(end_PID)
			begin
			ns = WAIT;
			clr = 1;
			end
		else
			begin
			ns = ERROR;
			PID_checked = 1;
			end
	 end
	 endcase
	 end

endmodule : pidFSM

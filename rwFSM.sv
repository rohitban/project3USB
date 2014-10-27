`define NONE_MSG 3'b000
`define IN_TOK 3'b001
`define OUT_TOK 3'b010
`define OUT_DATA 3'b011
`define IN_DATA 3'b100

`define OUT_TOK_RW 3'b101
`define IN_TOK_RW  3'b110

`define DATA_SIZE 7'd80
`define TOKEN_SIZE 6'd27
`define HSHAKE_SIZE 5'd16 

module rwFSM
	(input  logic clk, rst_L,

	 /* inputs from usbHost Tasks */
	 input  logic [15:0] RWmemPage,
	 input  logic [63:0] RW_data_write,
	 input  logic 			start_write, start_read,
	 /* outputs to usbHost Tasks */
	 output logic        read_success,
	 output logic 			write_success,
	 output logic [63:0] RW_data_read,
	 output logic 			rwFSM_done,

	 /* inputs from protocolFSM */
	 input  logic 			protocol_free,
	 input  logic 			timeout,
	 input  logic [63:0] rw_din,

	 /* outputs to ProtocolFSM */
	 output logic [2:0]  msg_type,
	 output logic [63:0] rw_dout
	 );
	
	logic [63:0] data_write_tmp, rev_data_write;
	logic [15:0] RWmemPage_tmp, rev_memPage;
   logic 		 ld_mempage, ld_w_data;
	logic 		 clr;

	enum logic [4:0] {WAIT, R_TOK_OUT_TEMP, W_TOK_OUT_TEMP,
							W_MEMPAGE_TEMP, W_TOK_OUT1_TEMP,
							R_TOK_OUT, R_MEMPAGE, 
							R_TOK_IN, R_DATA,
	 			  			W_TOK_OUT0, W_MEMPAGE, 
							W_TOK_OUT1, W_DATA, W_DATA_TEMP,
							R_MEMPAGE_TEMP,
							R_TOK_IN_TEMP,
							R_DATA_TEMP} cs,ns;


	always_ff@(posedge clk, negedge rst_L)
		if(~rst_L)
			cs <= WAIT;
		else
			cs <= ns;


	register  #(16)   mempage(.Q(RWmemPage_tmp), .D(RWmemPage), 
									  .ld(ld_mempage), .clr, 
									  .rst_n(rst_L), .clk);

	register  #(64)	 w_data(.Q(data_write_tmp), .D(RW_data_write), 
									  .ld(ld_w_data), .clr,
									  .rst_n(rst_L), .clk);

	always_comb begin
		/* registers */
		ld_mempage = 0;
		ld_w_data = 0;
	   clr = 0;	
		/* outputs to read/write tasks */
		rwFSM_done = 0;
		read_success = 0;
		write_success = 0;
		msg_type = `NONE_MSG;
		
		case(cs)
		WAIT : 
		begin
			if(start_read)
				begin
				//SEND TOKEN OUT PACKET
				ns = R_TOK_OUT_TEMP;
				ld_mempage = 1;
				end
			else if(start_write) 
				begin
				ns = W_TOK_OUT_TEMP;
				ld_mempage = 1;
				ld_w_data = 1;
				end
			else begin
				ns = WAIT;
				ld_mempage = 1;
				ld_w_data = 1;
			end
		end

		R_TOK_OUT_TEMP:
		begin
			ns = R_TOK_OUT;
			ld_mempage = 1;
			msg_type = `OUT_TOK;		    
		end

		W_TOK_OUT_TEMP:
		begin
			ns = W_TOK_OUT0;
			msg_type = `OUT_TOK;		    
			ld_mempage = 1;
		end
		/* READ */
		R_TOK_OUT : 
		begin
			if(protocol_free)   
				begin //TOKEN OUT packet has been sent
				ns = R_MEMPAGE_TEMP;
				//msg_type = `OUT_DATA; 
				//rw_dout = {48'h000000000000, RWmemPage_tmp};
				end
			else //still sending TOKEN OUT packet
				begin 
				ns = R_TOK_OUT;
				end
		end
		R_MEMPAGE_TEMP:
			begin
			ns = R_MEMPAGE;
			msg_type = `OUT_DATA;
			rev_memPage = {<<{RWmemPage_tmp}};
			rw_dout = {48'h000000000000, rev_memPage};
			end
		R_MEMPAGE : 
		begin
			//IF TIME OUT THEN END THE TRANSACTION
			if(timeout)     
				begin //DATA has not been sent but timeout
				ns = WAIT;
				rwFSM_done = 1;
				read_success = 0;  
				end
			else 
				if (protocol_free) 
				begin //DATA has been sent successfully
					ns = R_TOK_IN_TEMP;
				end
				else 
					begin
			  	//STILL TRYING TO SEND DATA
					ns = R_MEMPAGE;
					end
		end
		R_TOK_IN_TEMP:
			begin
				ns = R_TOK_IN;
				msg_type = `IN_TOK_RW;
			end
		R_TOK_IN : 
		begin
			if(protocol_free)      
				begin
				//TOKEN IN HAS BEEN SENT
				ns = R_DATA_TEMP;
				//msg_type = `IN_DATA; 
				end
			else 
				begin
			  //TOKEN IN IS STILL IN PROCESS
				ns = R_TOK_IN;
				end
		end
		R_DATA_TEMP:
			begin
			ns = R_DATA;
			msg_type = `IN_DATA;
			end
		R_DATA : 
		begin
			//IF TIME OUT THEN END TRANSACTION
			if(timeout)    
				begin
				ns = WAIT;
				rwFSM_done = 1;
				read_success = 0; 
				clr = 1;
				end
			else if (protocol_free) 
				begin
				//DATA HAS BEEN SENT
				ns = WAIT;
				rwFSM_done = 1;
				RW_data_read = rw_din; 
				read_success = 1;				  
				clr = 1;
				end
			else 
				begin
				ns = R_DATA;
				end
		end


		/* WRITE */
		W_TOK_OUT0 : begin
			if(protocol_free)   
				begin //TOKEN OUT packet has been sent
				//SNED DATA OUT
				ns = W_MEMPAGE_TEMP;
				//msg_type = `OUT_DATA; 
			  	//rw_dout = {48'h000000000000, RWmemPage_tmp}; 
				end
			else 
				begin//still sending TOKEN OUT packet
				ns = W_TOK_OUT0;
				end
		end
		W_MEMPAGE_TEMP:
			begin
				ns = W_MEMPAGE;
				msg_type = `OUT_DATA;
				rev_memPage = {<<{RWmemPage_tmp}};
			  	rw_dout = {48'h000000000000, rev_memPage}; 
			end

		W_MEMPAGE : begin
			if(timeout)     
				begin //DATA has not been sent but timeout
				ns = WAIT;
				rwFSM_done = 1;
				write_success = 0;  
				end
			else begin
				if(protocol_free) 
					begin //DATA has been sent successfully
					ns = W_TOK_OUT1_TEMP;
			  		//msg_type = `OUT_TOK;   
				end
				else 
					begin
					ns = W_MEMPAGE;
					end
			end
		end
		W_TOK_OUT1_TEMP:
		begin
			ns = W_TOK_OUT1;
			msg_type = `OUT_TOK_RW;
		end

		W_TOK_OUT1 : 
		begin
			if(protocol_free)      
				begin
				ns = W_DATA_TEMP;
				//msg_type = `OUT_DATA;
				//rw_dout = RW_data_write;  
				end
			else 
				begin
				ns = W_TOK_OUT1;
				end
		end
		
		W_DATA_TEMP:
			begin
			ns = W_DATA;
			msg_type = `OUT_DATA;
			rev_data_write = {<<{data_write_tmp}};
			rw_dout = rev_data_write;  
			end

		W_DATA : 
		begin
			if(timeout)    
				begin
				ns = WAIT;
				rwFSM_done = 1;
				write_success = 0; 
				clr = 1;
				end
			else if (protocol_free) 
				begin
				ns = WAIT;
				write_success = 1;
				rwFSM_done = 1;
				clr = 1;
				end
			else 
				begin
				ns = W_DATA;
				end
		end
	 endcase
	end
endmodule: rwFSM

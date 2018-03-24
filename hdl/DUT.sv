/***************************************************************************************************************************
*
*    File Name:  DUT.sv
*      Version:  1.0
*        Model:  Memory Controller
*
* Dependencies:  DUT_pkg.sv
*				 ddr3.sv (Memory Model)
*
*  Description:   Memory controller for Micron SDRAM DDR3-800 (Double Data Rate 3)
*
*   Functions :  - Performs following operations
*				   - POWERUP SEQUENCE, ZQ CALIBRATION, MODE REGISTER LOAD
*				   - ACTIVATE , WRITE, READ (Burst mode), PRECHARGE.
*				   - Works according to the timing specification followed by the memory model.
*				   - Timing specs : 6-6-6.

*****************************************************************************************************************************/

//===================================== PACKAGE IMPORT========================================================================
import DDR3MemPkg::* ;


//===================================== MODULE DECLARATION ===================================================================
module DDR3_Controller (
	input logic            i_cpu_ck   ,												// Main system clock 
	input logic            i_cpu_ck_ps,												// 90degree phase shifted clock
	mem_intf.MemController cont_if_cpu,												// Interface between CPU-CONTROLLER
	mem_if.contr_sig       cont_if_mem												// Interface between MEM-CONTROLLER
);


//===================================== LOCAL VARIABLES=======================================================================

	logic  [31:0] v_count                       ;	// Internal counter variable			
	logic  [31:0] max_count                = 'd0;   // variable to assign max count
	logic  [ 0:0] rst_counter              = 'd0;	// Reset counter variable
	logic         rw_flag,timer_intr            ;	// Flags for R/W and  Timer Interrupt
	logic         t_flag                        ;	// Timer Flag
	logic         dqs_valid                     ;	// DQS valid signal 
	bit           t_dqs_flag,t_dqsn_flag        ;   // internal flags for DQS and DQSN strobe
	logic  [15:0] wdata              [3:0]      ;	// 16 bit Write data
	logic  [15:0] rdata              [3:0]      ;	// 16 bit read data
	logic  [ 7:0] t_dq_local                    ;	
	logic  [15:0] wdata_local                   ;	// Local variable for write data
	logic  [15:0] rdata_local                   ;	// Local variable for read data
	logic         en                            ;	// Internal enable signeal
	logic  [26:0] s_addr                        ;	// 27 bit address variable
	logic  [63:0] s_data                        ;	// 64 bit data variable
	logic         s_valid_data_read             ;	// DAta valid during read
	logic  [ 7:0] temp1, temp2                  ;
	logic  [63:0] s_cpu_rd_data                 ;	// internal variable for CPU read operation 
	logic  [63:0] cpu_rd_data                   ;	
	logic         s_cpu_rd_data_valid           ;	// Valid signal for CPU read data
	logic         cpu_rd_data_valid             ;

	
	States        state                         ;   


//============================================================ INSTANTIATIONS============================================================================
// Instantiation of internal counter
	counter i_counter (.clock(i_cpu_ck), .reset(cont_if_cpu.i_cpu_reset), .en(en), .max_count(max_count), .done(timer_intr), .count(v_count));

// Instantiate of Write Burst module
	WriteBurst #(8) i_WriteBurst (.clock(i_cpu_ck_ps), .data(wdata_local), .out(t_dq_local), .valid_in(s_valid_data), .valid_out(dq_valid), .reset(cont_if_cpu.i_cpu_reset));
	
// Instantiation of read burst module
	read_burst #(8) i_ReadBurst (.clock(i_cpu_ck_ps), .data_in(cont_if_mem.dq), .out(rdata_local));

//============================================================ COMBINATIONAL ASSIGNMENTS=================================================================
	assign cont_if_mem.ck   = ~i_cpu_ck;											 	// Internal clock assignmnet 
	assign cont_if_mem.ck_n = i_cpu_ck;


	assign s_valid_data = (state==WBURST) & (v_count>=0);								// set s_valid_data in order to send the burst to memory	(Write operation)

	always_comb cont_if_cpu.o_cpu_data_rdy <= (state==IDLE);							// set ready signal from CPU when in IDLE state

//============================================================ SEQUENTIAL LOGIC===========================================================================
// Assign internal data and valid signals to CPU read and valid signals	
	always_ff@(posedge i_cpu_ck)
		begin
			cont_if_cpu.o_cpu_rd_data       <= cpu_rd_data;							
			cont_if_cpu.o_cpu_rd_data_valid <= s_cpu_rd_data_valid;					 
		end

// Read Burst operation. Provide 16 bits to the CPU per clock cycle.  
	always_ff @(negedge i_cpu_ck) begin : proc_r_burst
		if(cont_if_cpu.i_cpu_reset)										
			cpu_rd_data <= 0;
		else if(state==RBURST) 															
			unique case (v_count)													    
			3       : cpu_rd_data[63:48] <= rdata_local;
			2       : cpu_rd_data[47:32] <= rdata_local;
			1       : cpu_rd_data[31:16] <= rdata_local;
			0       : cpu_rd_data[15:0] <= rdata_local;
			default : cpu_rd_data <= 0;
		endcase
	end

//=================================================================== STATE TRANSITION BLOCK=========================================================
	always_ff@(posedge i_cpu_ck) begin
		if(cont_if_cpu.i_cpu_reset)											
			state <= POWERUP;										// state to POWERUP on reset
		else
			unique case(state)
				POWERUP : begin
					if(timer_intr)									// TXPR cycle meet to escape CKE high
						state <= ZQ_CAL;							// State to ZQ_CAL on timer interrupt
				end

				ZQ_CAL : begin
					if(timer_intr)
						state <= CAL_DONE;							// State to CAL_DONE on timer interrupt
				end

				CAL_DONE : begin
					state <= MRLOAD;								// State to MRLOAD on timer interrupt
				end

				MRLOAD : begin
					if(timer_intr)									
						state <= IDLE;								// State to IDLE on timer interrupt
				end

				IDLE : begin
					if(cont_if_cpu.i_cpu_valid)
						state <= ACT;								// State to ACT if CPU valid signal is high
				end

				ACT : begin
					if(timer_intr) begin
						if(rw_flag == 1)						    // Check for Read/Write
							state <= WRITE;							
						else
							state <= READ;
					end
				end

				WRITE : begin
					if(timer_intr)
						state <= WBURST;							//  State to WBURST on timer interrupt
				end

				READ : begin
					if(timer_intr)
						state <= RBURST;							// State to READ BURST on timer interrupt
				end

				WBURST : begin
					if(timer_intr)
						state <= AUTORP;							// State to PRECHARGE on timer interrupt
				end

				RBURST : begin
					if(timer_intr)
						state <= AUTORP;							// State to PRECHARGE on timer interrupt
				end

				AUTORP : begin
					if(timer_intr)
						state <= DONE;
				end

				DONE : begin
					state <= IDLE;
				end

				default : state <= POWERUP;							// State to POWERUP by default


			endcase
	end


//======================================================== OUTPUT BLOCK=============================================================================
// Begin with reseting the controller outputs to deassert condition.
	always_comb begin
		cont_if_mem.rst_n   = 1'b1;							// deassert reset signal
		cont_if_mem.odt     = 1'b1;						    // Set on die terminal signal
		cont_if_mem.ras_n   = 1'b1;							
		cont_if_mem.cas_n   = 1'b1;
		cont_if_mem.cs_n    = 1'b0;
		cont_if_mem.we_n    = 1'b1;
		cont_if_mem.ba      = 'b0;							// set bank address variable to 0
		cont_if_mem.addr    = 'b0;							// Set memory adddress variable to 0
		cont_if_mem.cke     = 'b1;							// Set Clock enable signal
		t_flag              = 'b0;				
		en                  = 'b0;							// set enable signal to 0
		s_cpu_rd_data_valid = 0;							// Set read data valid to 0
		s_cpu_rd_data       = 0;							// Set cpu data to 0
		case(state)
		// In this mode the DDR is powerup at clock cycle = 5 by setting rst_n to high and odt to 0	
		// After 9 clock cycles, odt is set along with performing chip select
			POWERUP : begin
				// RESET
				max_count         = 'd57;					
				cont_if_mem.rst_n = 1'b0;
				cont_if_mem.cke   = 1'b0;
				cont_if_mem.cs_n  = 1'b1;
				cont_if_mem.odt   = 1'b0;
				en                = 1'b1;
				// POWER UP AND CLOCKING DDR CHIP
				if(v_count>='d5) begin
					cont_if_mem.rst_n = 1'b1;
					cont_if_mem.odt   = 1'b0;
				end
				if(v_count>='d9) begin
					cont_if_mem.cke  = 1'b1;
					cont_if_mem.odt  = 1'b1;
					cont_if_mem.cs_n = 1'b0;
					cont_if_mem.odt  = 1'b0;
				end
			end

			// This state involves setting the A10 bit to enable the Auto Precharge Functionality 
			ZQ_CAL : begin
				max_count       = 'd1;
				en              = 1'b1;
				cont_if_mem.odt = 1'b0;
				// ZQ CALIBRATION PRECHARGING ALL THE BANKS
				if(v_count=='d0) begin
					cont_if_mem.we_n = 1'b0;
					cont_if_mem.ba   = 'd0;
					cont_if_mem.addr = 14'b00010000000000;
					cont_if_mem.odt  = 1'b0;
				end
			end

			// counter is set to max count of 4*T_MRD
			// Enable is set .
			// Mode registers are configured after every T_MRD clock cycle.
			MRLOAD : begin
				cont_if_mem.odt = 1'b0;
				max_count       = 4*T_MRD;
				en              = 1'b1;
				if(v_count=='d0) begin						// Mode Register0 with DLL Reset
					cont_if_mem.ras_n = 1'b0;
					cont_if_mem.cas_n = 1'b0;
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ba    = 3'b011;				// Config bank 3
					cont_if_mem.addr  = 14'b0;
					cont_if_mem.odt   = 1'b0;
				end
				else if(v_count==T_MRD) begin 				// Extended Mode Register1 with DLL Enable, AL=CL-1
					cont_if_mem.ras_n = 1'b0;
					cont_if_mem.cas_n = 1'b0;
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ba    = 3'b010;				// Config bank 2
					cont_if_mem.addr  = 14'b00000000000000;
					cont_if_mem.odt   = 1'b0;
				end
				else if(v_count==2*T_MRD) begin				// Extended Mode Register2 with DCC Disable
					cont_if_mem.ras_n = 1'b0;
					cont_if_mem.cas_n = 1'b0;
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ba    = 3'b001;				// Config Bank 1
					cont_if_mem.addr  = 14'b00000000010110;
					cont_if_mem.odt   = 1'b0;
				end
				else if(v_count==3*T_MRD) begin 			// Extended Mode Register3
					cont_if_mem.ras_n = 1'b0;
					cont_if_mem.cas_n = 1'b0;
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ba    = 3'b000;				// Config Bank 0
					cont_if_mem.addr  = 14'b00010100011000;
					cont_if_mem.odt   = 1'b0;
				end
			end

			// Reset on die termination
			CAL_DONE : cont_if_mem.odt   = 1'b0;			

			// Set the maximum count to T_RCD
			// During ACT, Bank and Row address are provided 
			// ras is assserted.
			// The controller has to wait for a period of Row-Column Delay
			ACT : begin
				max_count = T_RCD+1;
				en        = 1'b1;
				if(v_count=='d0) begin
					cont_if_mem.ba    = s_addr[12:10];		// 3 Bits for Bank
					cont_if_mem.addr  = s_addr[26:13];		// 14 row address bits
					cont_if_mem.ras_n = 1'b0;				// check if we_n should be asserted
				end
			end

			// 3LSBs are used for byte selec, which is why they are set to 0. 
			// Hence we obtain burst right from the first byte which reduces the delay
			// byte select is configurable (CRITICAL BYTE FIRST).
			READ : begin
				en              = 1'b1;
				max_count       = T_CL + 4;
				cont_if_mem.odt = 1'b0;
				if(v_count=='d0) begin
					cont_if_mem.we_n  = 1'b1;
					cont_if_mem.ba    = s_addr[12:10];			// provide bank address
					cont_if_mem.addr  = {s_addr[9:3],3'b0};		// 
					cont_if_mem.cas_n = 1'b0;
				end
			end

			WRITE : begin
				en        = 1'b1;
				max_count = T_CL-1+3;
				if(v_count=='d0) begin
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ba    = s_addr[12:10];
					cont_if_mem.addr  = {s_addr[9:3],3'b0};
					cont_if_mem.cas_n = 1'b0;
				end
			end

			
			RBURST : begin
				en              = 1'b1;									// Set enable
				max_count       = T_RAS-T_CL-T_RCD+1+2;					// set the max count
				cont_if_mem.odt = 1'b0; 
				if(v_count=='d3) begin
					s_cpu_rd_data_valid <= 1;
				end
			end

			// Write burst is performed using the write buffer. the memory provides 64 bits in chuncks of 8 in 4 clock cycles.
			// At every edge these 8 bits are captured and internally alligned to form 16 bits at the next clock edge.
			// After all 64 bits are obtained, the controller provides the entire 64 bits to the controller 
			WBURST : begin
				rst_counter = 'd0;
				en          = 1'b1;
				max_count   = T_RAS-T_CL-T_RCD+2;
				t_dqsn_flag = 'd0;
				wdata[0]    = s_data[15:0];
				wdata[1]    = s_data[31:16];
				wdata[2]    = s_data[47:32];
				wdata[3]    = s_data[63:48];
				t_flag      = (v_count > 0);
				if(v_count=='d0)
					wdata_local = wdata[0];
				else if(v_count=='d1)
					wdata_local = wdata[1];
				else if(v_count=='d2)
					wdata_local = wdata[2];
				else if(v_count=='d3)
					wdata_local = wdata[3];
			end

			// After every row is read, it is closed by performing auto precharge operation.
			// This is achieved by setting the A10 bit to 1 is the address.
			AUTORP : begin
				en        = 1'b1;
				max_count = T_RP;
				if(v_count=='d0) begin
					cont_if_mem.we_n  = 1'b0;
					cont_if_mem.ras_n = 1'b0;
					cont_if_mem.ba    = s_addr[12:10];
					cont_if_mem.addr  = 1<10;
				end
			end
		endcase
	end


//=====================================================TRI STATE LOGIC FOR BIDIRECTIONAL SIGNALS========================================================
// TRISTATING  DQ , DQS
	assign cont_if_mem.dq      = (dq_valid) 	? t_dq_local	:'bz ;							//assign dq to t_dq_local if dq_valid is set
	assign cont_if_mem.dqs     = (s_valid_data) ? i_cpu_ck		:'bz ;
	assign cont_if_mem.dqs_n   = (s_valid_data) ? ~i_cpu_ck		:'bz ;
	assign cont_if_mem.dm_tdqs = (dq_valid) 	? 0 			:'bz ;

// PROC FOR READ WRITE FLAG FROM CPU CMD DURING ACT STATE
	always_ff @(posedge i_cpu_ck or negedge cont_if_cpu.i_cpu_reset) begin : proc_rw
		if((cont_if_cpu.i_cpu_reset) | (state==DONE)) begin
			rw_flag <= 0;
		end else if (cont_if_cpu.i_cpu_valid & cont_if_cpu.i_cpu_cmd)
			rw_flag <= 1;;
	end

// PROC FOR internal address and data assignment during the IDLE state
	always_ff @(posedge i_cpu_ck) begin : proc_addr_data_lacth
		if(cont_if_cpu.i_cpu_reset) begin
			s_addr <= 0;
			s_data <= 0;
		end else if ((cont_if_cpu.i_cpu_valid) & (state==IDLE)) begin
			s_addr <= cont_if_cpu.i_cpu_addr;
			s_data <= cont_if_cpu.i_cpu_wr_data;
		end
	end

endmodule:DDR3_Controller

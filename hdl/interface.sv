/***************************************************************************************************************************
*
*    File Name:  interface.sv
*      Version:  1.0
*        Model:  Interface 
*
* Dependencies:  DUT.sv
*				 DDR3MemPkg.sv
*				 
*
*  Description:  contains 2 interfaces. 1. CPU-CONTROLLER    2. CONTROLLER-MEMORY
*				 Contains respective modports in each interface  
*


*****************************************************************************************************************************/

import DDR3MemPkg::* ;                     //Importing the variables for memory parameters and Address bit parameters
//==================================================================================================================================================
//Interface signals between MemController and DRAM memory
interface mem_if(input logic i_cpu_ck);	   //Clock from emulator mem_if Interface
	logic   rst_n;                         //Reset Signal
    logic   ck;                            // complement of CPU Clock
    logic   ck_n;                          //CPU Clock
    logic   cke;                           //Clock_enable from MemController to Memory
    logic   cs_n;                          //Chip Select Signal
    logic   ras_n;                         //RAS Signal row to column signal
    logic   cas_n;                         //CAS Signal column to data delay signal
    logic   we_n;                          //Write or read enable signal
    tri   [1-1:0]   dm_tdqs;
    logic   [BA_BITS-1:0]   ba;            // bank Bits 
    logic   [ADDR_BITS-1:0] addr;          //MAX Address Bits for the address bus
    tri   [DQ_BITS-1:0]   dq;              //data bits from/to memory controller form memory or CPU
    tri   [1-1:0]  dqs;                    //data strobe signal
    tri   [1-1:0]  dqs_n;                  //Checks if data is valid and assigned to complement of Cpu clock
    logic  [1-1:0]  tdqs_n;                //terminating Data strobe signal
    logic   odt;                           //on-die terminating Signal

//======Module port for controller signals===============================================================
	modport contr_sig (
		output ck, ck_n, rst_n, cs_n, cke, ras_n, cas_n, we_n, odt, ba, addr,tdqs_n,
		inout dm_tdqs, dq, dqs, dqs_n
	);


//======Module ports for Memory===========================================================================
	modport mem_sig (
		input ck, ck_n, rst_n, cs_n, cke, ras_n, cas_n, we_n, odt,ba, addr,tdqs_n,
		inout dm_tdqs,dq, dqs, dqs_n
	);


endinterface : mem_if

///////////////////////// Interface for Driver///////////////////////////


//==================================================================================================================================================
//Interface between CPU and Memory Controller
interface mem_intf(input logic i_cpu_ck);
   
  	//logic	     				i_cpu_ck;		// Clock from TB
	logic	     				i_cpu_reset;	// Reset passed to Controller from TB
	logic [ADDR_MCTRL-1:0]		i_cpu_addr;  	// Cpu Addr
	logic 	     				i_cpu_cmd;		// Cpu command RD or WR
	logic [8*DQ_BITS-1:0]		i_cpu_wr_data;	// Cpu Write Data 
	logic 	     				i_cpu_valid;	// Valid is set when passing CPU addr and command
	logic 	     				i_cpu_enable;	// Chip Select
	logic [BURST_L-1:0]  		i_cpu_dm;		// Data Mask - One HOT
	logic [$clog2(BURST_L):0]	i_cpu_burst;	// Define Burst Length - wont be used for now
	logic [8*DQ_BITS-1:0]		o_cpu_rd_data;	// Cpu data Read
	logic	     				o_cpu_data_rdy;	// Cpu data Ready	
	logic 						o_cpu_rd_data_valid; // Signal for valid data sent to CPU   
	

  modport MemController (
		input   i_cpu_ck,                    // Clock from TB
		input 	i_cpu_reset,               //Reset passed to controller from TB
		input 	i_cpu_addr,                //CPU Address to MemController
		input 	i_cpu_cmd,                 //CPU command Read or write
		input 	i_cpu_wr_data,             //CPU write Data
		input 	i_cpu_valid,               //Valid is set when passing CPU Addr and Command
		input 	i_cpu_enable,              //Enable Signal
		input 	i_cpu_dm,                  //Data mask-One Hot
		input 	i_cpu_burst,               //Defining the Burst Lenght
		output  o_cpu_rd_data,             //CPU data Read
		output  o_cpu_data_rdy,	           //CPU data Ready
		output 	o_cpu_rd_data_valid);      //Signal for Valid data sent to CPU

int count;
  
//==================================================================================================================================================
//Reset Function -Reset Condition (Signal to reset the MemController)
task Reset();                                                     //Reset Function -Reset Condition (Signal to reset the MemController)
		@(posedge i_cpu_ck);                                      //At first posedge of Clock from TB
		$display("--------- [DRIVER] Reset Started ---------");   
		i_cpu_reset = 1;                                          //Reset signal is made high
		i_cpu_valid = 0;                                          // Valid signal Set low
		i_cpu_enable= 0;                                          //deselecting the CPU enable signal
		@(posedge i_cpu_ck);                                      //At Second Posedge clk
		i_cpu_reset = 0;                                          //Reset Signal to 0
		i_cpu_enable = 1;                                         //Enabling the CPU Enable Signal
		$display("--------- [DRIVER] Reset Ended---------");
endtask
                                                                                 //Signals needed to be asserted while in write operation
//==================================================================================================================================================
//sending 64  bits of data from CPU to MemController and the required signals need to be asserted in write operation
task Write(logic [ADDR_MCTRL-1:0] address, logic [8*DQ_BITS-1:0] write_data);    //passing Address and write data to memory Controller
	@(posedge i_cpu_ck);                                                         //At Posedge of Clock
		wait (o_cpu_data_rdy);                                                   //wait till cpu data is ready
		@(posedge i_cpu_ck);                                                     //if cpu data ready in the coming posedge of clock
		i_cpu_valid=1'b1;                                                        //Address valid to 1 ,address valid
		i_cpu_cmd=1'b1;                                                          //write command to MemController
		if (i_cpu_valid && i_cpu_cmd) begin									     //if valid and write enable are both high 				
				i_cpu_addr=address;                                              //address is stored in i_cpu_addr
				i_cpu_wr_data=write_data;                                        //cpu write data i_cpu_wr_data
		end
		@(posedge i_cpu_ck);                                                     //in the next clock cycle
		i_cpu_valid=0;                                                           //making the valid signal to go low
endtask                                                                          //end write task

                                                                                     //Signals needed to be asserted while in read operation
//==================================================================================================================================================
//Sendin the data from  MemController to CPU and the required signals need to be asserted in read operation
task Read(logic [ADDR_MCTRL-1:0] address, output logic [8*DQ_BITS-1:0] read_data );  //passing Address as Input and taking out data from memory Controller
	@(posedge i_cpu_ck); 															 //At Posedge of Clock
		wait(o_cpu_data_rdy);                                                        //wait till cpu data is ready
		@(posedge i_cpu_ck);                                                         //if cpu data ready in the coming posedge of clock
		i_cpu_valid=1'b1;  															 //Address valid to 1 ,address valid
		i_cpu_cmd=1'b0;																 //Read command to MemController
		if (i_cpu_valid && ~i_cpu_cmd) begin										 //checking if read operation from cpu is valid
				i_cpu_addr=address;                                                  //address is stored in i_cpu_addr
				@(posedge i_cpu_ck);                                                 //in the next clock cycle
				i_cpu_valid=0;                                                       //making the valid signal to go low
				wait(o_cpu_rd_data_valid);                                           //wait till valid signal from MemController
				//@(posedge i_cpu_ck);
				read_data = o_cpu_rd_data;                                           //Capturing the data from CPU
				end
		
endtask                                                                              //end read operation
                                                                                     //Run -Operation
//==================================================================================================================================================
//checks the address and data coming from cpu depending on that it does the required operations R/W opearions if the memoery controller is in 
//IDLE State 
task run(logic valid, logic cmd, logic [ADDR_MCTRL-1:0] address,                     //passing Valid,Command(R/W),Address,Write Data
         logic [8*DQ_BITS-1:0] wr_data, output logic [8*DQ_BITS-1:0] rd_data);       //output data from MemController if read 
		$display("count=%d", count++);
		@(posedge i_cpu_ck);                                                          //in the posedge of clock cycle
		wait (o_cpu_data_rdy);                                                        //wait till cpu data is ready
		@(posedge i_cpu_ck);                                                          //in the posedge of clock cycle
		if(valid) begin                                                               //if valid is High
		@(posedge i_cpu_ck);                                                          //in the posedge of clock cycle
		i_cpu_valid=valid;                                                            //assign valid from CPU to Interface valid 
		i_cpu_cmd=cmd;                                                                //assign valid from CPU to Interface valid 
		if (valid && cmd) begin										                  //if valid and write enable are both high then write operation				
				i_cpu_addr=address;                                                   //address is sent to i_cpu_addr (MemController)
				i_cpu_wr_data=wr_data;                                                //write data to interface(MemController)
				@(posedge i_cpu_ck);                                                  //in the posedge of clock cycle
				i_cpu_valid=0;                                                        //making the valid signal to go low
				end
		
		if (valid && ~cmd) begin												      //if valid is high and write enable is low then read operation										// Read
				i_cpu_addr=address;                                                   //address is sent to i_cpu_addr (MemController)
				@(posedge i_cpu_ck);                                                  //in the posedge of clock cycle
				i_cpu_valid=0;                                                        //making the valid signal to go low
				@(posedge o_cpu_rd_data_valid);                                       //at posedge of data valid
				//@(posedge i_cpu_ck);
				rd_data = o_cpu_rd_data;                                              //outof data from MemController to cpu
				end
		end
endtask                                                                               //end the task for Run Operation

endinterface : mem_intf                                                               //end mem_intf






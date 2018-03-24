/***************************************************************************************************************************
*
*    File Name:  Data_O_Burst.sv
*      Version:  1.0
*        Model:  Read Burst
*
* Dependencies: DUT.sv 
*				 
*
*  Description:  Receives 8 bits per clock edge from the memory.
*				 After one clock cycle, concatenates the 8 bits to for a 16 bit output.
*
* Rev   Author   Date        Changes
* ---------------------------------------------------------------------------------------
* 0.1    SA      02/28/18    FSM design
* 0.42  JMK      08/25/06    Created internal clock using ck and ck_n.

*****************************************************************************************************************************/


module read_burst #(parameter BW = 8)(input logic clock,   //Read Burst from Memory to Memory Controller
				  input logic [BW-1:0] data_in,            // input Data to  dram Buffers
				  output logic [BW*2-1:0] out);            //  output read data

//==================================================================================================================================================
// Local variables
logic [BW-1:0] temp1;								       // Temperory variable to store output data
logic [BW-1:0] temp2;
logic valid_out;								           // Data assigned to CPU only if valid_out is set

//==================================================================================================================================================
//DRAM buffer , at every poesedge and negedge of clk we capture 8 bits of data and send it 16 bits of Data in every clock cycles to Memory Controller
always @ (posedge clock) begin            //in the posedge of the clock we store first 8 bits of data in temp2
	temp2 <= data_in;
end

always @ (negedge clock) begin            //in the negedge of the clock we store next 8 bits of data in temp2
	temp1 <= data_in;
end

always_ff @ (negedge clock) begin         //in the posedge of the clock we send the 16 bits of data
	out <= {temp2, temp1};
end

endmodule // read_burst
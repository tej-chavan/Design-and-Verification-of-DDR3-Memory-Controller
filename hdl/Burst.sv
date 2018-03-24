/***************************************************************************************************************************
*
*    File Name:  Burst.sv
*      Version:  1.0
*        Model:  Write burst
*
* Dependencies:  DUT_pkg.sv
*				 
*
*  Description:  Performs the burst operation by writing by taking 16 bits per clock cycle as inputs
*				 Sends 8 bits of data at every clock edge to the memory.
*
*

*****************************************************************************************************************************/

module WriteBurst #(parameter BW=8)(      //Write Burst 
	input  logic        clock    ,        //Input clock
	input  logic        reset    ,        //Input Reset 
	input  logic [2*BW-1:0] data     ,    //Input data to Memory Controller
	input  logic        valid_in ,        //Input Reset
	output logic [BW-1:0] out      ,      // Data out  in 8 bits
	output logic        valid_out         //Valid Data out Signal
);
	logic [BW-1:0] temp1;                 //Temperory variable to store output data
	logic [BW-1:0] temp2;                 //Temperory variable to store output data
	logic valid_out1,valid_out2;          //Valid Signal for temp1,temp2 data is valid 

	
//==================================================================================================================================================
	assign out = (clock) ? temp2 : temp1;           //Sending out data as it is centre aligned for write

	assign valid_out = (valid_out1 & valid_out2);   //Valid is asserted high if both the temp1 and temp2 valid signals are high
	
//==================================================================================================================================================
//keep the track of data to be send to memory at every posedge and negdedge by setting the valid signal 
	always_ff @(negedge clock) begin : proc_valid1  
		if(reset) begin                             //In negedge of Clock if reset is assigned to 0
			valid_out1 <= 0;
		end else begin                              
			valid_out1 <= valid_in;                 //valid signal from Memory Controller
		end
	end
	always_ff @(posedge clock) begin : proc_valid2  //Valid signal for data
		if(reset) begin                             //In negedge of Clock if reset valid is assigned to 0
			valid_out2 <= 0;
		end else begin
			valid_out2 <= valid_in;                 //valid signal from Memory Controller
		end
	end
	
//==================================================================================================================================================
//send the data to Memory in chunks of 8 bits in every posedge and negedge of Clock Cycle
	always @ (posedge clock) begin            //Capturing LSB of 8 bits in posedge of clock
		if(valid_in)
			temp1 <= data[BW-1:0];
	end
	always @ (negedge clock) begin            //Capturing MSB of 8 bits in negedge of clock
		if(valid_in)
			temp2 <= data[2*BW-1:BW];
	end

//==================================================================================================================================================
endmodule:WriteBurst


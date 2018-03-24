/////////////////////////Driver Class///////////////////////////
package driver_p;

import transaction_p::* ;
import generator_p::*;
import DDR3MemPkg::* ;

class driver;
   
  //used to count the number of transactions
  int no_transactions;
  
  int count;
  
  logic [2**BA_BITS-1:0][8*DQ_BITS-1:0] memory_write = 
  {{4{16'h1403}},{4{16'h1225}}, {4{16'h0312}}, {4{16'h0876}},{4{16'h1025}}, {4{16'h6512}}, {4{16'h1385}}, {4{16'h4213}}} ; // Data to be written
  logic [2**BA_BITS-1:0][8*DQ_BITS-1:0] memory_read;
  logic [8*DQ_BITS-1:0] data_read;
  logic [2**BA_BITS-1:0][ADDR_MCTRL-1:0] address = {32'h00341c09, 32'h00931886, 32'h00901509, 32'h00101082, 32'h00998c02, 32'h00024882, 32'h00e1040f, 32'h00404282};
  
  
  
  //creating virtual interface handle
  virtual mem_intf mem_vif;
  //creating mailbox handle
  mailbox gen2driv;
  mailbox mon2scb;
   
  //constructor
function new(virtual mem_intf mem_vif, mailbox gen2driv, mailbox mon2scb);
    //getting the interface
    this.mem_vif = mem_vif;
    //getting the mailbox handle from  environment
    this.gen2driv = gen2driv;
	//this.driverm_vif = driverm_vif;
	this.mon2scb = mon2scb ;
endfunction

task reset();
	mem_vif.Reset();
endtask


task directed_test();
	mem_vif.Write(address[7], memory_write[7]);
	mem_vif.Read(address[7], data_read);						// Simple data write and read
	//$display("data_read=%h", data_read);
	if (data_read[63:56]==='z && !$isunknown(data_read[55:0]))
		$warning("Simulation issues");
	else begin
	if (memory_write[7] === data_read)
		$display("Scenario 1: Simple Data write and read----Data read has matched with the Data written");
	else
		$error("Scenario 1: Corrupt data read");
	end
	
	mem_vif.Write(address[6], memory_write[7]);
	mem_vif.Write(address[6], memory_write[6]);					// Overwrite data on the same address
	mem_vif.Read(address[6], data_read);
	if (data_read[63:56]==='z && !$isunknown(data_read[55:0]))
		$warning("Simulation issues");
	else begin
	if (memory_write[6] === data_read)
		$display("Scenario 2: Overwrite data on the same address----Data read has matched with the Data written");
	else
		$error("Scenario 2: Corrupt data read");
	end
	
	mem_vif.Write(32'h00341cf9, memory_write[5]);				// Same row, different column
	mem_vif.Read(32'h00341cf9, data_read);
	if (data_read[63:56]==='z && !$isunknown(data_read[55:0]))
		$warning("Simulation issues");
	else begin
	if (memory_write[5] === data_read)
		$display("Scenario 3: Same row , Different column----Data read has matched with the Data written");
	else
		$error("Scenario 3: Corrupt data read");
	end
	
	mem_vif.Write(32'h00e41cf9, memory_write[2]);				// Different row, same bank
	mem_vif.Read(32'h00e41cf9, data_read);
	if (data_read[63:56]==='z && !$isunknown(data_read[55:0]))
		$warning("Simulation issues");
	else begin
	if (memory_write[2] === data_read)
		$display("Scenario 4: Same bank, Different row ----Data read has matched with the Data written");
	else
		$error("Scenario 4: Corrupt data read");
	end
	
endtask

task consecutive_addresses();	
	logic [ADDR_MCTRL-1:0] base_address = 32'h00000000;  
	logic [ADDR_MCTRL-1:0] start_address, actual_address;
	logic [8*DQ_BITS-1:0] read_data;
	
	for (int j=0; j<4; j++)
	begin
		start_address = {base_address[31:15],j[1:0],base_address[12:0]};
		for (int i=0;i<(2**(COL_BITS-3));i++)
		begin 
			logic [8*DQ_BITS-1:0] random_data = {$urandom,$urandom};
			actual_address = {start_address[31:10],i[6:0],start_address[2:0]};
			mem_vif.Write(actual_address, random_data);   
			//$display("send_data=%h\n", send_data);
			mem_vif.Read(actual_address, read_data);
				if (read_data[63:56]==='z && !$isunknown(read_data[55:0]))
					$warning("Simulation issues");
				else begin
					if (random_data === read_data)
						$display("Scenario 5: Same row, Consecutive Columns ----Data read has matched with the Data written");
					else
						$error("Scenario 5: Corrupt data read");
				end
		
		end	
		$display("Row %0d access done", j);
	end
	//$finish;
endtask

task write();
	for (int i=0;i<(2**BA_BITS);i++)
	begin 
	mem_vif.Write(address[i], memory_write[i]);   // Single write to every bank
	//$display("memory_write[%d]=%h\n",i,memory_write[i]);
	end	
endtask

task read();
	for (int i=0;i<(2**BA_BITS);i++)
	begin
	mem_vif.Read(address[i], memory_read[i]);	// Read from the written addresses 
	//$display("memory_read[%d]=%h\n",i,memory_read[i]);
	end
endtask

task compare();
	//$display ("memory_read=%h, memory_write=%h", memory_read,memory_write);
	if (memory_read===memory_write)
		$display("Data read from all banks has matched with the Data written to all banks");
	else 
		$error("Corrupt data read from one or more banks");
endtask

task drive();
	repeat(count) begin
		transaction trans;
		gen2driv.get(trans); 
		mem_vif.run(trans.i_cpu_valid, trans.i_cpu_cmd, trans.i_cpu_addr, trans.i_cpu_wr_data, trans.o_cpu_rd_data);
		mon2scb.put(trans);
		no_transactions++;
	end
endtask
       
endclass

endpackage


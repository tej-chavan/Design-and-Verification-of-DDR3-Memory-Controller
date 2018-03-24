///////////////////////// Transaction Class ////////////////////////////
package transaction_p;

import DDR3MemPkg::* ;

class transaction;

rand bit 	[ADDR_MCTRL-1:0] 	i_cpu_addr;
rand bit 	[8*DQ_BITS-1:0]	 	i_cpu_wr_data;
rand logic 						i_cpu_cmd;
rand logic 						i_cpu_valid;

//logic 	[ADDR_MCTRL-1:0] 	i_cpu_addr = 32'h00001280;
//logic 	[8*DQ_BITS-1:0]	 	i_cpu_wr_data=64'h0000230000000003;
//logic 						i_cpu_cmd=1;
//logic 						i_cpu_valid=1;


logic 							i_cpu_enable;
logic 							i_cpu_reset;
logic 		[8*DQ_BITS-1:0] 	o_cpu_rd_data;
logic                     		o_cpu_data_rdy;
logic 							o_cpu_rd_data_valid;

constraint addr{i_cpu_addr inside {[0:(2**27)-1]};}

endclass

endpackage

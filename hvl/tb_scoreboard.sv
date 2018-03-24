

package scoreboard_p;

import DDR3MemPkg::* ;
import transaction_p::* ;


class scoreboard;
    
  //creating mailbox handle
  mailbox mon2scb;
   
  //used to count the number of transactions
  int no_transactions;
  int count; 
  
  //array to use as local memory
  bit [8*DQ_BITS-1:0] mem[bit [ADDR_MCTRL-1:0]];
   
  //constructor
  function new(mailbox mon2scb);
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;
    //foreach(mem[i]) mem[i] = 8'hFF;
  endfunction
   
  //stores wdata and compare rdata with stored data
  task main;
    transaction trans;
    repeat(count) begin
      //#50;
	  //if(mon2scb.num()!=0) begin
      mon2scb.get(trans);
      if(trans.i_cpu_valid && ~trans.i_cpu_cmd /*&& hdltop.cpu_contr.o_cpu_rd_data_valid*/) begin			//Read 
		if(!mem.exists(trans.i_cpu_addr))
			$display("memory location not written to be read");
		else begin
		if(mem[trans.i_cpu_addr] != trans.o_cpu_rd_data)
          $error("[SCB-FAIL] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.i_cpu_addr,mem[trans.i_cpu_addr],trans.o_cpu_rd_data);
        else
          $display("[SCB-PASS] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.i_cpu_addr,mem[trans.i_cpu_addr],trans.o_cpu_rd_data);
		end
	  end
      else if(trans.i_cpu_valid && trans.i_cpu_cmd && trans.i_cpu_addr[31:24]==8'h00 /*&& hdltop.cpu_contr.o_cpu_data_rdy*/) begin			//Write
        mem[trans.i_cpu_addr] = trans.i_cpu_wr_data;
		$display($time, " mem[%h] = %h ", trans.i_cpu_addr, trans.i_cpu_wr_data);
		end
      no_transactions++;
    //end
	end
  endtask
   
endclass

endpackage
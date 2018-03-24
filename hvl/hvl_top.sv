//`timescale 1ps/1ps

class top;

virtual mem_intf intf;
 
task set_vif (virtual mem_intf intf);
        this.intf = intf;
endtask

endclass
 
module hvltop;
   
  /*clock and reset signal declaration
  bit clock;
  bit Reset;
   
  //clock generation
  always #5 clock = ~clock;
   
  //reset Generation
  initial begin
    Reset = 1;
    #5 Reset =0;
	#1000 $stop;
  end
   */
  //creating instance of interface, inorder to connect DUT and testcase
  // hdltop.cpu_contr intf/*(hdltop.i_cpu_ck)*/;
   
  
  top inst;
  initial
  begin
	inst= new;
	inst.set_vif(hdltop.cpu_contr);
  end
  
  //Testcase instance, interface handle is passed to test as an argument
  test t1(hdltop.cpu_contr);
  
  
endmodule
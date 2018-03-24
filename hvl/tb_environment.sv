//////////////////////////////// Environment class /////////////////////////
//`include "tb_transaction.sv"
//`include "tb_generator.sv"

/*`include "tb_driver.sv"
`include "tb_monitor.sv"
`include "tb_scoreboard.sv"
`include "tb_generator.sv"
*/
package environment_p; 

import transaction_p::*;
import generator_p::*;
import driver_p::*;
//import monitor_p::*;
import scoreboard_p::*;

class environment;
   
  //generator and driver instance
  generator gen;
  driver    driv; 
//  monitor    mon;    
  scoreboard scb;
   
  //mailbox handle's
  mailbox gen2driv;
  mailbox mon2scb;
  
   
  //event for synchronization between generator and test
  event gen_ended;
   
  //virtual interface
  virtual mem_intf mem_vif;
  //virtual mem_intf.DRIVER driverm_vif;
   
  //constructor
  function new(virtual mem_intf mem_vif);
    //get the interface from test
    this.mem_vif = mem_vif;
	//this.driverm_vif = driverm_vif;
     
    //creating the mailbox (Same handle will be shared across generator and driver)
    gen2driv = 	new();
	mon2scb  = 	new();
     
    //creating generator, driver and scoreboard
    gen  = 	new(gen2driv,gen_ended);
	driv = 	new(mem_vif,gen2driv,mon2scb);
//	mon  = 	new(mem_vif, mon2scb);
	scb	 = 	new(mon2scb);
  endfunction
 
task pre_test();
    driv.reset();
	driv.directed_test();			// Directed test cases
	driv.consecutive_addresses();	// Write and Read from continuous addresses
	driv.write();   				// Single write to every bank
	driv.read();					// Read from the written addresses 
	driv.compare();					// Self check to verify written and read data
endtask
   
task test();
    fork
		gen.main();					// Generate random stimulus
		driv.drive();				// Drive the random stimulus
//		mon.main();
		scb.main();					//Verify the Results 
	join_any
endtask
   
task post_test();
    wait(gen_ended.triggered);
	$display ("event triggered");
    wait(gen.repeat_count == driv.no_transactions);
	$display ("event triggered1");
	wait(gen.repeat_count == scb.no_transactions);
endtask 
   
  //run task
task run();
    pre_test();
    test();
    post_test();
    $finish;
endtask
   
endclass

endpackage
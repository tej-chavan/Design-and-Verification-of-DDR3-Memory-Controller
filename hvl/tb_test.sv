

//`include "tb_environment.sv"

program test(mem_intf intf);
import environment_p::* ;

  
  //declaring environment instance
  environment env;
   
  initial begin
    //creating environment
    env = new(intf);
     
    //setting the repeat count of generator as 10, means to generate 10 packets
    env.gen.repeat_count = 1000;
	env.driv.count = 1000;
	env.scb.count = 1000;
     
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram
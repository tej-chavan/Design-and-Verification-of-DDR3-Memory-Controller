
/*
`include "tb_transaction.sv"
*/
//////////////////////// Generator Class ///////////////////////////
package generator_p;

import transaction_p::*;

class generator;
   
  //declaring transaction class
  rand transaction trans;
   
  //declaring mailbox
  mailbox gen2driv;
   
  //repeat count, to specify number of items to generate
  int  repeat_count; 
 
  //event
  event ended;
 
  //constructor
  function new(mailbox gen2driv,event ended);
    //getting the mailbox handle from env
    this.gen2driv = gen2driv;
    this.ended    = ended;
  endfunction
   
  //main task, generates(create and randomizes) the repeat_count number of transaction packets and puts into mailbox
  task main();
    repeat(repeat_count) begin
      trans = new();
      if( !trans.randomize() ) $fatal("Gen:: trans randomization failed");   
      gen2driv.put(trans);
    end
   -> ended;
  endtask 

endclass


endpackage

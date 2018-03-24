
run:
		vsim -c work.hdltop work.hvltop -do "run -all; quit"
all:
	vlib work
	# HDL Compilation
	vlog -work work ./hdl/DUT_pkg.sv 
	vlog -work work ./hdl/interface.sv 
	vlog -work work ./memory_model/1024Mb_ddr3_parameters.sv
	vlog -work work ./memory_model/ddr3.sv
	vlog -work work ./hdl/*.sv 
	# HVL Compilation
	vlog -work work ./hvl/tb_transaction.sv 
	vlog -work work ./hvl/tb_generator.sv
	vlog -work work ./hvl/tb_driver.sv
	vlog -work work ./hvl/tb_scoreboard.sv
	vlog -work work ./hvl/tb_environment.sv
	vlog -work work ./hvl/tb_test.sv
	vlog -work work ./hvl/hvl_top.sv
	vlog -work work ./hvl/top.sv
	vsim -c work.hdltop work.hvltop -do "run -all; quit"
design:
	# HDL Compilation
	vlog -work work ./hdl/DUT_pkg.sv 
	vlog -work work ./hdl/interface.sv 
	vlog -work work ./memory_model/1024Mb_ddr3_parameters.sv
	vlog -work work ./memory_model/ddr3.sv
	vlog -work work ./hdl/*.sv 
update:
	# HVL Compilation		
	vlog -work work ./hvl/tb_transaction.sv 
	vlog -work work ./hvl/tb_generator.sv
	vlog -work work ./hvl/tb_driver.sv
	vlog -work work ./hvl/tb_scoreboard.sv
	vlog -work work ./hvl/tb_environment.sv
	vlog -work work ./hvl/tb_test.sv
	vlog -work work ./hvl/hvl_top.sv
	vlog -work work ./hvl/top.sv
	vsim -c work.hdltop work.hvltop -do "run -all; quit"

coverage:
		vlib work
	# HDL Compilation
	vlog +cover -work work ./hdl/DUT_pkg.sv 
	vlog +cover -work work ./hdl/interface.sv 
	vlog +cover -work work ./memory_model/1024Mb_ddr3_parameters.sv
	vlog +cover -work work ./memory_model/ddr3.sv
	vlog +cover -work work ./hdl/*.sv 
	# HVL Compilation
	vlog +cover -work work ./hvl/tb_transaction.sv 
	vlog +cover -work work ./hvl/tb_generator.sv
	vlog +cover -work work ./hvl/tb_driver.sv
	vlog +cover -work work ./hvl/tb_scoreboard.sv
	vlog +cover -work work ./hvl/tb_environment.sv
	vlog +cover -work work ./hvl/tb_test.sv
	vlog +cover -work work ./hvl/hvl_top.sv
	vlog +cover -work work ./hvl/top.sv
	vsim -c -coverage work.hdltop work.hvltop -do "run -all; quit"

clean:
	rm -rf work transcript vsim.wlf


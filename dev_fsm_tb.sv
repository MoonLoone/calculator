`timescale 1 ps/ 1 ps

//command bit definitions
import cmd_bits::*;

module dev_fsm_tb();

	//parameters
	parameter DW = 8;

	// test vector input registers
	logic clk;
	logic cs;
	logic [DW-1:0] din;
	logic rst;
	// module output connections
	logic busy;
	logic [DW-1:0] dout;
	logic drdy;
	// testbench variables
	logic [DW-1:0] res;

    //device under test
	dev_fsm #(.DW(DW)) dut (
		.busy(busy),
		.clk(clk),
		.cs(cs),
		.din(din),
		.dout(dout),
		.drdy(drdy),
		.rst(rst)
	);

	// create clock
	initial                                                
	begin                                                  
		clk=0;
		forever #10 clk=~clk;
	end                                                    

	// reset circuit and run several transactions
	initial
	begin
		// reset
		rst=0;
		@(negedge clk) rst=1;
		//skip one edge after reset
		@(posedge clk);
		// Custom
		// write second operand for tests
		write_transaction((1<<b_op_2),0,$random,res); 
		// two operand sum
		write_transaction((1<<b_op_2)|(1<<b_addop),$random,$random,res);
		//read result
		write_transaction((1<<b_tx),0,0,res);
		// add operand to result
		write_transaction((1<<b_addres),$random,$random,res);
		// write second operand for tests
		//write_transaction((1<<b_op_2),0,$random,res); 
		// sub operator
		write_transaction((1<<b_subres),$random,0,res);
		//read result
		write_transaction((1<<b_tx),0,0,res);
		//wait couple clock cycles
		repeat (5) @(posedge clk);
		//stop simulation
		$stop;
	end
	
	//basic transaction with module
	task write_transaction;
		//input signals
		input [DW-1:0] cmd;
		input [DW-1:0] op_1;
		input [DW-1:0] op_2;
		output [DW-1:0] result;
		//transaction implementation
		begin
			//wait while device is busy
			while (busy) @(posedge clk);
			//set chip select and write command to DUT
			cs=1;
			din=cmd;
			//clear chip select
			@(posedge clk);
			cs=0;
			//write op_1 if required and wait for one clock cycle
			if (cmd[b_subres] || cmd[b_addres] || cmd[b_subop] || cmd[b_addop])
			begin 
				din=op_1;
				@(posedge clk);
			end
			//write op_2 if required and wait for one clock cycle
			if (cmd[b_op_2]) 
			begin 
				din=op_2;
				@(posedge clk);
			end
			//if read is supposed, wait for rdy to latch result
			if (cmd[b_tx]) 
			begin
				while (!drdy) @(posedge clk);
				result = dout;
			end
			else result = 'bx;
		end
	endtask
	
endmodule


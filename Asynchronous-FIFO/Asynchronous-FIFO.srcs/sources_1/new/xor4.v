	/*______________________________________________________________________
	* *
	* The logic modules below are coded explicitly, to ensure *
	* that the logic is implemented in a minimum of levels. *
	______________________________________________________________________*/
	module xor4 (
							data, 
							out
							);
							
	input 		[3:0] 	data;
	output	 					out;
	
	assign #1 			out 	= (data[3] ^ data[2]^ data[1]^ data[0]);
	endmodule
	

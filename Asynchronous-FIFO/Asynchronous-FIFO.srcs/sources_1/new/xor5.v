	/*______________________________________________________________________
	* *
	* The logic modules below are coded explicitly, to ensure *
	* that the logic is implemented in a minimum of levels. *
	______________________________________________________________________*/
	module xor5 (
							data, 
							out
							);
							
	input 	[4:0] 	data;
	output 					out;
	
	wire muxout, mdata1, mdata0;
	
	assign #1  	mdata1		= ! (data[4] ^ data[3]^ data[2]^ data[1]);
	assign #1  	mdata0		= 	(data[4] ^ data[3]^ data[2]^ data[1]);
	
	MUXF5 muxf5_1 (
							.I0(mdata0), 
							.I1(mdata1), 
							.S(data[0]), 
							.O(muxout)
							);
							
	assign #1 out = muxout;
	endmodule
	

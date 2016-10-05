	/*______________________________________________________________________
	* *
	* The logic modules below are coded explicitly, to ensure *
	* that the logic is implemented in a minimum of levels. *
	______________________________________________________________________*/
	
	module muxor(
							a, 
							b, 
							c, 
							sel, 
							out
							);
							
	input 		a, b, c, sel;
	output 		out;
	
	assign #1 		out = ( ((a == b) && sel) || ((a == c) && ! sel) );
	
	endmodule 
	/*___________________________________________________________

 The logic modules below are coded explicitly, to ensure that 
 the logic is implemented in a minimum of levels.  
	___________________________________________________________*/
	
	module and4b1 (
						input 	in1,
						input 	in2,
						input 	in3,
						input 	in4,
						output	out
						);
			
		assign out = in1 && in2 && in3 && in4 ;
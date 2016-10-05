	/*___________________________________________________________

 The logic modules below are coded explicitly, to ensure that 
 the logic is implemented in a minimum of levels.  
	___________________________________________________________*/
	
	module and4b4 (
						input 	[3:0]	data,
						output	out
						);
			
		assign out = data[3] & data[2]  & data[1]  & data[0] ;
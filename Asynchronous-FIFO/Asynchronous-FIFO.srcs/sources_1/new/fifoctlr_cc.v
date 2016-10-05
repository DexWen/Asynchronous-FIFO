`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/10/04 11:04:40
// Design Name: 
// Module Name: fifoctlr_cc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define DATA_WIDTH 7:0
`define ADDR_WIDTH 8:0

//___ top Module ___
module fifoctlr_cc (
						clock_in,
						read_enable_in,  
						write_enable_in,
						write_data_in, 
						fifo_gsr_in,  	// gsr global signal reset
						read_data_out,
						full_out,  
						empty_out, 
						fifocount_out
						);
						
//__________ input ___________						
	input 								clock_in;
	input 								read_enable_in; 	
	input									write_enable_in; 	
	input									fifo_gsr_in;
	input  	[`DATA_WIDTH] write_data_in;
	
//__________ output ___________	
	output 	[`DATA_WIDTH] read_data_out;
	output 								full_out;  				
	output								empty_out;
	output 	[3:0] 				fifocount_out;

	wire 									read_enable		= 	read_enable_in;
	wire 									write_enable	= 	write_enable_in;
	wire 									fifo_gsr			= 	fifo_gsr_in;
	wire 		[`DATA_WIDTH] write_data		= 	write_data_in;
	wire 		[`DATA_WIDTH] read_data;
	
	assign 								read_data_out	= 	read_data;
	reg										full, 						empty;
	assign 								full_out			= 	full;
	assign 								empty_out			= 	empty;
	
	
	reg 		[`ADDR_WIDTH] read_addr	, 			write_addr, 			fcounter;
	reg 									read_allow, 			write_allow;
	wire 									fcnt_allow;
	wire 		[`DATA_WIDTH]	gnd_bus				= 	'h0;
	wire 									gnd						= 	0;
	wire								 	pwr						= 	1;
	
	//____________________________________________________________
	//__A global buffer is instantiantedto avoid skew problems.___
	
	BUFGP 	gclk1 (
								.I(clock_in), 
								.O(clock)
								);
								
	/*____________________________________________________________
	
		Block RAM  instantiationfor FIFO. Module is 512x8, of which one 
		address location is sacrificed for the overall speed of the design.
	____________________________________________________________*/				
	
	RAMB4_S8_S8  bram1 ( 
					.ADDRA(read_addr), 
					.ADDRB(write_addr), 
					.DIA(gnd_bus),
					.DIB(write_data), 
					.WEA(gnd), 
					.WEB(pwr), 
					.CLKA(clock),	
					.CLKB(clock), 
					.RSTA(gnd), 
					.RSTB(gnd), 
					.ENA(read_allow),
					.ENB(write_allow), 
					.DOA(read_data),.DOB() 
					);
					
	//___Set allow flags, which control the clock enables for read, write, and count operations.
	wire 	[3:0] 			fcntandout;
	wire 							ra_or_fcnt0,  	wa_or_fcnt0, 	emptyg, fullg;
	
		//___read_allow___
		always @(posedge clock or posedge fifo_gsr)
		if (fifo_gsr) 			read_allow 	<= 	0;
		else 								read_allow 	<= 	read_enable 	&& !( fcntandout[0] && fcntandout[1] && ! write_allow );
		
		//___write_allow___
		always @(posedge clock or posedge fifo_gsr)
		if (fifo_gsr) 			write_allow	<= 	0;
		else 								write_allow	<= 	write_enable 	&& !( fcntandout[2] && fcntandout[3] && ! read_allow );
		
	assign fcnt_allow = write_allow^ read_allow;
	
	/*____________________________________________________________
			Empty flag is set on  fifo_gsr(initial), or when on the next clock cycle, Write Enable is low, and either the 
			FIFOcountis equal to 0, or it is equal to 1 and Read 
			Enable is high (about to go Empty).  
	__________________________________________________________*/
	
	assign ra_or_fcnt0		= 	(read_allow || ! fcounter[0]);
	
	and4b4 emptyand1 (
									.data(fcounter[4:1]), 
									.out(fcntandout[0])
									);
	and4b4 emptyand2 (
									.data(fcounter[8:5]), 
									.out(fcntandout[1])
									);
	and4b1 emptyand3 (
									.in1(fcntandout[0]), 
									.in2(fcntandout[1]), 
									.in3(ra_or_fcnt0),
									.in4(write_allow), 
									.out(emptyg)
									);
									
	//_________empty________								
	always @(posedge clock or posedge fifo_gsr)
		if (fifo_gsr)			empty 	<= 	1;
		else	 						empty 	<= 	emptyg;
	
	
	/*____________________________________________________________

	 Full flag is set on fifo_gsr(but it is cleared on the  first 
	 valid clock edge after fifo_gsris removed), or when on the 
	 next clock cycle, Read Enable is low, and either the 
	 FIFOcountis equal to  1FF(hex), or it is equal to 1FE and 
	 the Write Enable is high (about to go Full). 
	________________________________________________________*/			

	assign wa_or_fcnt0	= (write_allow ||  fcounter[0]);
	and4b4  fulland1 (
						.data	(fcounter[4:1]), 
						.out	(fcntandout[2])
						);
	and4b4  fulland2 (
						.data	(fcounter[8:5]), 
						.out	(fcntandout[3])
						);
	and4b1 fulland3 (
						.in1(fcntandout[2]), 
						.in2(fcntandout[3]), 
						.in3(wa_or_fcnt0),
						.in4(read_allow), 
						.out(fullg)	
						);
	always @(posedge clock or posedge fifo_gsr)
	if (fifo_gsr)			full 	<= 	1;
	else 							full 	<= 	fullg;	
	
	
	/*__________________________________________________________________

	 Generation of Read and Write address pointers. They now  use binary
	 counters because it is simpler in simulation,  and the previous LFSR
	 implementation wasn't in the  critical path. 
	___________________________________________________________________*/
//___ read_addr ___
	always @(posedge clock or posedge fifo_gsr)
	if (fifo_gsr) 				read_addr 	<= 	'h0;
	else if (read_allow) 	read_addr 	<= 	read_addr + 1;
//___ write_addr ___
	always @(posedge clock or posedge fifo_gsr)
	if (fifo_gsr) 				write_addr	<= 	'h0;
	else if (write_allow) write_addr	<= 	write_addr+ 1;
	
	
	/*__________________________________________________________________
	
		Generation of FIFOcount outputs. Used to determine how full FIFO is,
		based on a counter that keeps track of how many words are in the FIFO. 
		Also used to generate Full and Empty flags. Only the upper four bits
		of the counter are sent outside the FIFO module.
	___________________________________________________________________*/

	always @(posedge clock or posedge fifo_gsr)
	if (fifo_gsr) 					fcounter 	<= 	'h0;
	else if (fcnt_allow)		fcounter 	<= 	fcounter + { read_allow, read_allow, read_allow,read_allow, read_allow, read_allow,	read_allow, read_allow, pwr};
	
	assign 									fifocount_out	= fcounter[8:5];
	endmodule

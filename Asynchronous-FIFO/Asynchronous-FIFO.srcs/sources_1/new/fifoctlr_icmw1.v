	`timescale 1ns/  10ps
	//____ `define ____
	`define DATA_WIDTHR			3:0
	`define DATA_WIDTHW			15:0
	`define ADDR_WIDTH			7:0
	`define MINORADDR_WIDTH	1:0
	`define CARRY_WIDTH			7:0

	module 	fifoctlr_icmw1  (
													read_clock_in,  
													write_clock_in, 
													read_enable_in,
													write_enable_in, 
													fifo_gsr_in,  
													write_data_in,
													read_data_out,  
													full_out,  
													empty_out, 
													fifostatus_out 
													);
	//_____ input _____												
	input 										read_clock_in,  		write_clock_in;
	input 										read_enable_in, 		write_enable_in ;
	input 										fifo_gsr_in;
	input  	[`DATA_WIDTHW] 		write_data_in;
	
	//_____ outnput _____	
	output 	[`DATA_WIDTHR]  	read_data_out;
	output 										full_out,  				empty_out;
	output 	[3:0] 						fifostatus_out;
	
	//_____ wire parameter _____
	wire 											read_enable		= 	read_enable_in;
	wire 											write_enable	= 	write_enable_in;
	wire 											fifo_gsr			= 	fifo_gsr_in;
	wire 		[`DATA_WIDTHW] 		write_data		= 	write_data_in;
	wire 		[`DATA_WIDTHR]  	read_data;
	
	assign 										read_data_out	= 	read_data;
	//_____	reg _____
	reg			[7:0] 						fifostatus;
	assign 										fifostatus_out= 	fifostatus[7:4];
	
	reg												full, 	empty;
	assign 										full_out			= 	full;
	assign 										empty_out			= 	empty;
	
	reg 		[`ADDR_WIDTH] 		read_addr;				
	reg			[`ADDR_WIDTH]  		write_addr;
	reg 		[`ADDR_WIDTH] 		write_addrgray, 	write_nextgray;
	reg 		[`ADDR_WIDTH] 		read_addrgray,  	read_nextgray,  read_lastgray;
	reg 		[`MINORADDR_WIDTH] read_addr_minor;
	wire 		[`CARRY_WIDTH] 		ecomp, 						fcomp;
	wire 		[`CARRY_WIDTH] 		emuxcyo, 					fmuxcyo;
	
	wire 											read_allow, write_allow, read_allow_minor;
	wire 											full_allow, empty_allow;
	wire 											emptyg, fullg;
	wire 		[`DATA_WIDTHR]  	gnd_bus				= 	'h0;
	wire 											gnd						= 	0;
	wire 											pwr						= 	1;
	/*______________________________________________________________________
		Global input clock buffers are instantiantedfor both the read_clock
		and the write_clock,to avoid skew problems. 		
	______________________________________________________________________*/
	BUFGP gclkread (
									.I(read_clock_in), 
									.O(read_clock)
									);
	BUFGP gclkwrite (
									.I(write_clock_in), 
									.O(write_clock)
									);
	
	/*______________________________________________________________________
	
	Block Select RAM  instantiation for FIFO. Module is 256x16, of which one 
	address location is sacrificed for the overall speed of the design. 
	NOTE: the 4-bit read data will come out  LSB to MSB relative to the o
	riginal 16-bit word written. e.g. the first 4-bit nibble will be word[3:0],
	then [7:4], [11:8] and finally [15:12].  
	______________________________________________________________________*/
	
	//___ 1020x4 Read, 255x16 Write 
/*	RAMB4_S4_S16  ram_uut ( 
									.clka (read_clock), 
									.ena (read_allow_minor), 							//1
									.wea(gnd), 														//1									
									.addra({read_addr, read_addr_minor}), //8+2 	bits
									.dina(gnd_bus), 												//4			bits
									.douta(read_data),											//4

									.clkb(write_clock), 
									.enb(write_allow),										//1									
									.web(pwr),														//1									
									.addrb(write_addr),										//8			bits
									.dinb(write_data), 										//16		bits					
									.doutb() 
									);*/
	blk_mem_gen_0 ram_uut (
								  .clka(read_clock),    									// input wire clka
								  .ena(read_allow_minor),      						// input wire ena
								  .wea(gnd),      												// input wire [0 : 0] wea
								  .addra({read_addr, read_addr_minor}),  	// input wire [9 : 0] addra
								  .dina(gnd_bus),    											// input wire [15 : 0] dina
								  .douta(read_data),  										// output wire [3 : 0] douta
								  
								  .clkb(write_clock),    									// input wire clkb
								  .enb(write_allow),      								// input wire enb
								  .web(pwr),      												// input wire [0 : 0] web
								  .addrb(write_addr),  										// input wire [9 : 0] addrb
								  .dinb(write_data),    									// input wire [15 : 0] dinb
								  .doutb()  															// output wire [3 : 0] doutb
								);
	
	
	/*______________________________________________________________________
	
	* Allow flags determine whether FIFO control logic can operate. If 
	 read_enable is driven high, and the FIFO is not Empty, then Reads 
	 are allowed. Similarly, if the write_enable signal is high, and the 
	 FIFO is not Full, then Writes are allowed. *
	______________________________________________________________________*/
	
	assign	read_allow_minor 	= 	(read_enable 			&& ! empty);
	assign 	read_allow 				= 	(read_allow_minor && (read_addr_minor == 2'b11));	// why is 2'b11? becasue the read width is 1020 x 4
	assign 	write_allow				= 	(write_enable			&& ! full);
	assign 	full_allow 				= 	(full 						||  write_enable);
	assign 	empty_allow				= 	(empty 						||  (read_enable && (read_addr_minor == 2'b11)));
	
	
	
	/*______________________________________________________________________
	
	* Empty flag is set on fifo_gsr(initial), or when gray *
	* code counters are equal, or when the special decoding *
	* logic is true (see below for full/empty decoding). *
	______________________________________________________________________*/
	
	always @(posedge read_clock or posedge fifo_gsr)
			if (fifo_gsr)								empty <= 'b1;
			else if (empty_allow)				empty <= emptyg;
	
	
	/*______________________________________________________________________
	
	* Full flag is set on  fifo_gsr(initial, but it is cleared *
	* on the first valid  write_clockedge after fifo_gsris *
	* de-asserted), or when the special decoding logic is *
	* true (see below for full/empty decoding). *
	______________________________________________________________________*/
	always @(posedge write_clock or posedge fifo_gsr)
			if (fifo_gsr)								full <= 'b1;
			else if (full_allow)				full <= fullg;
	
	
	
	/*______________________________________________________________________
	* *
	* Generation of Read address pointers. The primary one is *
	* binary  (read_addr),and the Gray-code derivatives are *
	* generated via pipeliningthe binary-to-Gray-code result. *
	* The initial values are important, so they're in sequence. *
	* There is a minor address created for the port with the *
	* smaller data width, which in this case is the read port. *
	* *
	*  Grey-codeaddresses are used so that the registered *
	* Full and Empty flags are always clean, and never in an *
	* unknown state due to the asynchonousrelationship of the *
	* Read and Write clocks. In the worst case scenario, Full *
	* and Empty would simply stay active one cycle longer, but *
	* it would not generate an error or give false values. *
	* *
	______________________________________________________________________*/
	//____ read_addr ____
	always @(posedge read_clock or posedge fifo_gsr)
		if (fifo_gsr) 					read_addr 		<= 	'h0;
		else if (read_allow) 		read_addr 		<= 	read_addr + 1;
	
	//____ read_nextgray ____	
	always @(posedge read_clock or posedge fifo_gsr)
		if (fifo_gsr) 					read_nextgray	<= 	8'b10000000;
		else if (read_allow)
														read_nextgray	<= 	{ read_addr[7], (read_addr[7] ^ read_addr[6]),
																						(read_addr[6] ^ read_addr[5]), (read_addr[5] ^ read_addr[4]),
																						(read_addr[4] ^ read_addr[3]), (read_addr[3] ^ read_addr[2]),
																						(read_addr[2] ^ read_addr[1]), (read_addr[1] ^ read_addr[0])};	
																						// 另一种转换格雷码方法 (read_addr >> 1) ^ read_addr
																						
	//____ read_addrgray ____																						
	always @(posedge read_clock or posedge fifo_gsr)
		if (fifo_gsr) 					read_addrgray	<= 8'b10000001;
		else if (read_allow) 		read_addrgray	<= read_nextgray;
	
	
	//____ read_lastgray ____				
	always @(posedge read_clock or posedge fifo_gsr)
		if (fifo_gsr) 					read_lastgray	<= 8'b10000011;
		else if (read_allow) 		read_lastgray	<= read_addrgray;	
	
	
	/*______________________________________________________________________
	* *
	* Generation of Write address pointers. Identical copy of *
	* read pointer generation above, except for names. *
	* *
	______________________________________________________________________*/
	
	//____ write_addr ____	
	always @(posedge write_clock or posedge fifo_gsr)
			if (fifo_gsr) 					write_addr			<= 	'h0;
			else if (write_allow) 	write_addr			<= 	write_addr+ 1;
	
	//____ read_lastgray ____	
	always @(posedge write_clock or posedge fifo_gsr)
			if (fifo_gsr) 					write_nextgray	<= 8'b10000000;
			else if (write_allow)
														write_nextgray	<= 	{ write_addr[7], (write_addr[7] ^ write_addr[6]),
																								(write_addr[6] ^ write_addr[5]), (write_addr[5] ^ write_addr[4]),
																								(write_addr[4] ^ write_addr[3]), (write_addr[3] ^ write_addr[2]),
																								(write_addr[2] ^ write_addr[1]), (write_addr[1] ^ write_addr[0])};
																								// 另一种转换格雷码方法 (write_addr >> 1) ^ write_addr
	
	//____ write_addrgray ____		
	always @(posedge write_clock or posedge fifo_gsr)
			if (fifo_gsr) 					write_addrgray	<= 8'b10000001;
			else if (write_allow) 	write_addrgray	<= write_nextgray;
	
	
	/*______________________________________________________________________
	* *
	* Generation of minor addresses for read operations. Bits *
	* are sent to the LSB of the Block  SelectRAM read address, *
	* and are used to determine when to increment  read_addr.*
	* *
	______________________________________________________________________*/
	//____ read_addr_minor ____	
	always @(posedge read_clock or posedge fifo_gsr)
			if (fifo_gsr) 								read_addr_minor 	<= 	'h0;
			else if (read_allow_minor)	 	read_addr_minor 	<= 	read_addr_minor + 1;
	
	
	/*______________________________________________________________________
	* *
	* Alternative generation of FIFOstatus outputs. Used to *
	* determine how full FIFO is, based on how far the Write *
	* pointer is ahead of the Read pointer.  read_truegray* 
	* is synchronized to  write_clock (rag_writesync),converted *
	* to binary  (ra_writesync),and then subtracted from the *
	*  pipelined write_addr (write_addrr)to find out how many *
	* words are in the FIFO (fifostatus).The top bits are * 
	* then 1/2 full, 1/4 full, etc. (not mutually exclusive). *
	*  fifostatus has a one-cycle latency on  write_clock;or, *
	* one cycle after the write address is incremented on a * 
	* write operation, fifostatus is updated with the new * 
	* capacity information. There is a two-cycle latency on *
	* read operations. *
	* *
	* If read_clockis much faster than  write_clock,it is * 
	* possible that the fifostatus counter could drop several *
	* positions in one write_clockcycle, so the low-order bits *
	* of fifostatus are not as reliable. *
	* *
	* NOTE: If the fifostatus flags are not needed, then this *
	* section of logic can be trimmed, saving 20+ slices and *
	* improving the circuit performance. *
	* *
	______________________________________________________________________*/
	
	reg 	[`ADDR_WIDTH] 	read_truegray,  rag_writesync, write_addrr;
	wire 	[`ADDR_WIDTH] 	ra_writesync;
	wire 	[2:0] 					xorout;
	
	//____ read_truegray ____
	always @(posedge read_clock or posedge fifo_gsr)
			if (fifo_gsr) 					read_truegray	<= 'h0;
			else	 									read_truegray	<= { read_addr[7], (read_addr[7] ^ read_addr[6]),
																								(read_addr[6] ^ read_addr[5]), (read_addr[5] ^ read_addr[4]),
																								(read_addr[4] ^ read_addr[3]), (read_addr[3] ^ read_addr[2]),
																								(read_addr[2] ^ read_addr[1]), (read_addr[1] ^ read_addr[0])};
																						
	//____ rag_writesync ____																						
	always @(posedge write_clock or posedge fifo_gsr)
			if (fifo_gsr)		 				rag_writesync	<= 	'h0;
			else 										rag_writesync	<= 	read_truegray;
	
	xor4  	xor7_4 (
									.data(rag_writesync[7:4]), 
									.out(xorout[0])
									);
									
	xor5  	xor7_3 (
									.data(rag_writesync[7:3]), 
									.out(xorout[1])
									);
									
	xor4  	xor3_0 (
									.data(rag_writesync[3:0]), 
									.out(xorout[2])
									);
									
	assign 	ra_writesync	= {
															rag_writesync[7], (rag_writesync[7] ^ rag_writesync[6]),
															(rag_writesync[7] ^ rag_writesync[6] ^ rag_writesync[5]),
															xorout[0], xorout[1], (xorout[1] ^ rag_writesync[2]),
															(xorout[1] ^ rag_writesync[2] ^ rag_writesync[1]),
															(xorout[0] ^ xorout[2])
															};
															
	//____ write_addrr ____	
		always @(posedge write_clock or posedge fifo_gsr)
				if (fifo_gsr) 			write_addrr	<= 	'h0;
				else 								write_addrr	<= 	write_addr;
			
	//____ fifostatus ____	
	always @(posedge write_clock or posedge fifo_gsr)
				if (fifo_gsr) 			fifostatus 	<= 	'h0;
				else if (! full) 		fifostatus 	<= 	write_addrr- ra_writesync;
			
			
	/*______________________________________________________________________
	* *
	* The two conditions decoded with special carry logic are *
	* Empty and Full (gated versions). These are used to *
	* determine the next state of the Full/Empty flags. Carry *
	* logic is used for optimal speed. (The previous *
	* implementation of Almost Empty and  Almost Full have been *
	* wrapped into the corresponding carry chains for faster *
	* performance). *
	* *
	* When write_addrgray is equal to  read_addrgray, the FIFO *
	* is Empty, and emptyg(combinatorial) is asserted. Or, *
	* when  write_addrgray is equal to read_nextgray(1 word in *
	* the FIFO) then the FIFO potentially could be going Empty, *
	* so emptyg is asserted, and the Empty flip-flop enable is *
	* gated with empty_allow,which is conditioned with a valid *
	* read. * 空标志由读脉冲产生
	* *
	* Similarly, when read_lastgray is equal to  write_addrgray,*
	* the FIFO is full (255 addresses). Or, when  read_lastgray*
	* is equal to  write_nextgray,then the FIFO potentially *
	* could be going Full, so fullg is asserted, and the Full *
	* flip-flop enable is gated with  full_allow,which is *
	* conditioned with a valid write. * 满标志由写脉冲产生
	* *
	* Note: To have utilized the full address space (256) *
	* would have required extra logic to determine Full/Empty *
	* on equal addresses, and this would have slowed down the *
	* overall performance, which was the top priority. *
	* *
	______________________________________________________________________*/
	muxor emuxor0  (
									.a(write_addrgray[0]), 
									.b(read_addrgray[0]),
									.c(read_nextgray[0]), 
									.sel(empty), 
									.out(ecomp[0])
									);
									
	muxor emuxor1  (
								.a(write_addrgray[1]), 
								.b(read_addrgray[1]),
								.c(read_nextgray[1]), 
								.sel(empty), 
								.out(ecomp[1])
								);
	muxor emuxor2  (
								.a(write_addrgray[2]), 
								.b(read_addrgray[2]),
								.c(read_nextgray[2]), 
								.sel(empty), 
								.out(ecomp[2])
								);
	muxor emuxor3  (
								.a(write_addrgray[3]), 
								.b(read_addrgray[3]),
								.c(read_nextgray[3]), 
								.sel(empty), .out(ecomp[3])
								);
	muxor emuxor4  (
								.a(write_addrgray[4]), 
								.b(read_addrgray[4]),
								.c(read_nextgray[4]), 
								.sel(empty), 
								.out(ecomp[4])
								);
	muxor emuxor5  (
								.a(write_addrgray[5]), 
								.b(read_addrgray[5]),
								.c(read_nextgray[5]), 
								.sel(empty), 
								.out(ecomp[5])
								);
	muxor emuxor6  (
								.a(write_addrgray[6]), 
								.b(read_addrgray[6]),
								.c(read_nextgray[6]), 
								.sel(empty), 
								.out(ecomp[6])
								);
	muxor emuxor7  (
								.a(write_addrgray[7]), 
								.b(read_addrgray[7]),
								.c(read_nextgray[7]), 
								.sel(empty), 
								.out(ecomp[7])
								);
	
	MUXCY_L emuxcy0 (
								.DI(gnd), 
								.CI(pwr),  
								.S(ecomp[0]), 
								.LO(emuxcyo[0])
								);
	
	MUXCY_L emuxcy1 (
								.DI(gnd), 
								.CI(emuxcyo[0]), 
								.S(ecomp[1]), 
								.LO(emuxcyo[1])
								);
	
	MUXCY_L emuxcy2 (
								.DI(gnd), 
								.CI(emuxcyo[1]), 
								.S(ecomp[2]), 
								.LO(emuxcyo[2])
								);
								
	MUXCY_L emuxcy3 (
								.DI(gnd), 
								.CI(emuxcyo[2]), 
								.S(ecomp[3]), 
								.LO(emuxcyo[3])
								);
								
	MUXCY_L emuxcy4 (
								.DI(gnd), 
								.CI(emuxcyo[3]), 
								.S(ecomp[4]), 
								.LO(emuxcyo[4])
								);
	
	MUXCY_L emuxcy5 (
								.DI(gnd), 
								.CI(emuxcyo[4]), 
								.S(ecomp[5]), 
								.LO(emuxcyo[5])
								);
								
	MUXCY_L emuxcy6 (
								.DI(gnd), 
								.CI(emuxcyo[5]), 
								.S(ecomp[6]), 
								.LO(emuxcyo[6])
								);
								
	MUXCY_L emuxcy7 (
								.DI(gnd), 
								.CI(emuxcyo[6]), 
								.S(ecomp[7]), 
								.LO(emptyg)
								);
	
	muxor fmuxor0  (
								.a(read_lastgray[0]), 
								.b(write_addrgray[0]),
								.c(write_nextgray[0]), 
								.sel(full), 
								.out(fcomp[0])
								);
	
	muxor fmuxor1  (
								.a(read_lastgray[1]), 
								.b(write_addrgray[1]),
								.c(write_nextgray[1]), 
								.sel(full), .out(fcomp[1])
								);
	
	muxor fmuxor2  (
								.a(read_lastgray[2]), 
								.b(write_addrgray[2]),
								.c(write_nextgray[2]), 
								.sel(full), 
								.out(fcomp[2])
								);
								
	muxor fmuxor3  (
								.a(read_lastgray[3]), 
								.b(write_addrgray[3]),
								.c(write_nextgray[3]), 
								.sel(full), 
								.out(fcomp[3])	
								);
	
	muxor fmuxor4  (
							.a(read_lastgray[4]), 
							.b(write_addrgray[4]),
							.c(write_nextgray[4]), 
							.sel(full), 
							.out(fcomp[4])
							);
					 
				
	muxor fmuxor5  (
							.a(read_lastgray[5]), 
							.b(write_addrgray[5]),
							.c(write_nextgray[5]), 
							.sel(full), 
							.out(fcomp[5])
							);
							
	muxor fmuxor6  (
							.a(read_lastgray[6]), 
							.b(write_addrgray[6]),
							.c(write_nextgray[6]), 
							.sel(full), 
							.out(fcomp[6])
							);
	
	muxor fmuxor7  (
							.a(read_lastgray[7]), 
							.b(write_addrgray[7]),
							.c(write_nextgray[7]), 
							.sel(full), 
							.out(fcomp[7])
							);
							
	MUXCY_L fmuxcy0 (.DI(gnd), .CI(pwr),  .S(fcomp[0]), .LO(fmuxcyo[0]));
	MUXCY_L fmuxcy1 (.DI(gnd), .CI(fmuxcyo[0]), .S(fcomp[1]), .LO(fmuxcyo[1]));
	MUXCY_L fmuxcy2 (.DI(gnd), .CI(fmuxcyo[1]), .S(fcomp[2]), .LO(fmuxcyo[2]));
	MUXCY_L fmuxcy3 (.DI(gnd), .CI(fmuxcyo[2]), .S(fcomp[3]), .LO(fmuxcyo[3]));
	MUXCY_L fmuxcy4 (.DI(gnd), .CI(fmuxcyo[3]), .S(fcomp[4]), .LO(fmuxcyo[4]));
	MUXCY_L fmuxcy5 (.DI(gnd), .CI(fmuxcyo[4]), .S(fcomp[5]), .LO(fmuxcyo[5]));
	MUXCY_L fmuxcy6 (.DI(gnd), .CI(fmuxcyo[5]), .S(fcomp[6]), .LO(fmuxcyo[6]));
	MUXCY_L fmuxcy7 (.DI(gnd), .CI(fmuxcyo[6]), .S(fcomp[7]), .LO(fullg));
	
	endmodule 
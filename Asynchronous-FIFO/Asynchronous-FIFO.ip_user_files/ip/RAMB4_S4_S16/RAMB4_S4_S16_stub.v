// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.2 (win64) Build 1577090 Thu Jun  2 16:32:40 MDT 2016
// Date        : Wed Oct 05 10:06:34 2016
// Host        : DESKTOP-C1GVFD3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               h:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.srcs/sources_1/ip/RAMB4_S4_S16/RAMB4_S4_S16_stub.v
// Design      : RAMB4_S4_S16
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module RAMB4_S4_S16(DOA, DOB, ADDRA, ADDRB, CLKA, CLKB, DIA, DIB, ENA, ENB, RSTA, RSTB, WEA, WEB)
/* synthesis syn_black_box black_box_pad_pin="DOA[3:0],DOB[15:0],ADDRA[9:0],ADDRB[7:0],CLKA,CLKB,DIA[3:0],DIB[15:0],ENA,ENB,RSTA,RSTB,WEA,WEB" */;
  output [3:0]DOA;
  output [15:0]DOB;
  input [9:0]ADDRA;
  input [7:0]ADDRB;
  input CLKA;
  input CLKB;
  input [3:0]DIA;
  input [15:0]DIB;
  input ENA;
  input ENB;
  input RSTA;
  input RSTB;
  input WEA;
  input WEB;
endmodule

-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.2 (win64) Build 1577090 Thu Jun  2 16:32:40 MDT 2016
-- Date        : Wed Oct 05 10:06:34 2016
-- Host        : DESKTOP-C1GVFD3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               h:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.srcs/sources_1/ip/RAMB4_S4_S16/RAMB4_S4_S16_stub.vhdl
-- Design      : RAMB4_S4_S16
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx485tffg1761-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RAMB4_S4_S16 is
  Port ( 
    DOA : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DOB : out STD_LOGIC_VECTOR ( 15 downto 0 );
    ADDRA : in STD_LOGIC_VECTOR ( 9 downto 0 );
    ADDRB : in STD_LOGIC_VECTOR ( 7 downto 0 );
    CLKA : in STD_LOGIC;
    CLKB : in STD_LOGIC;
    DIA : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DIB : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ENA : in STD_LOGIC;
    ENB : in STD_LOGIC;
    RSTA : in STD_LOGIC;
    RSTB : in STD_LOGIC;
    WEA : in STD_LOGIC;
    WEB : in STD_LOGIC
  );

end RAMB4_S4_S16;

architecture stub of RAMB4_S4_S16 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "DOA[3:0],DOB[15:0],ADDRA[9:0],ADDRB[7:0],CLKA,CLKB,DIA[3:0],DIB[15:0],ENA,ENB,RSTA,RSTB,WEA,WEB";
begin
end;

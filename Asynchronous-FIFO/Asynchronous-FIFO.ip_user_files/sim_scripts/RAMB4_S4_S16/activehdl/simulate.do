onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+RAMB4_S4_S16 -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -L xpm -L blk_mem_gen_v8_3_3 -O5 xil_defaultlib.RAMB4_S4_S16 xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {RAMB4_S4_S16.udo}

run -all

endsim

quit -force

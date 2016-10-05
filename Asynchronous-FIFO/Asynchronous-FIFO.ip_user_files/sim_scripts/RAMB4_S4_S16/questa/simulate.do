onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib RAMB4_S4_S16_opt

do {wave.do}

view wave
view structure
view signals

do {RAMB4_S4_S16.udo}

run -all

quit -force

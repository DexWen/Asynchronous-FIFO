proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param simulator.modelsimInstallPath E:/modeltech64_10.1c/win64
  set_property design_mode GateLvl [current_fileset]
  set_param project.singleFileAddWarning.threshold 0
  set_property webtalk.parent_dir H:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.cache/wt [current_project]
  set_property parent.project_path H:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.xpr [current_project]
  set_property ip_repo_paths h:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.cache/ip [current_project]
  set_property ip_output_repo h:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.cache/ip [current_project]
  set_property XPM_LIBRARIES XPM_MEMORY [current_project]
  add_files -quiet H:/git/Asynchronous-FIFO/Asynchronous-FIFO/Asynchronous-FIFO.runs/synth_1/fifoctlr_icmw1.dcp
  link_design -top fifoctlr_icmw1 -part xc7vx485tffg1761-2
  write_hwdef -file fifoctlr_icmw1.hwdef
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  opt_design 
  write_checkpoint -force fifoctlr_icmw1_opt.dcp
  report_drc -file fifoctlr_icmw1_drc_opted.rpt
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  implement_debug_core 
  place_design 
  write_checkpoint -force fifoctlr_icmw1_placed.dcp
  report_io -file fifoctlr_icmw1_io_placed.rpt
  report_utilization -file fifoctlr_icmw1_utilization_placed.rpt -pb fifoctlr_icmw1_utilization_placed.pb
  report_control_sets -verbose -file fifoctlr_icmw1_control_sets_placed.rpt
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force fifoctlr_icmw1_routed.dcp
  report_drc -file fifoctlr_icmw1_drc_routed.rpt -pb fifoctlr_icmw1_drc_routed.pb
  report_timing_summary -warn_on_violation -max_paths 10 -file fifoctlr_icmw1_timing_summary_routed.rpt -rpx fifoctlr_icmw1_timing_summary_routed.rpx
  report_power -file fifoctlr_icmw1_power_routed.rpt -pb fifoctlr_icmw1_power_summary_routed.pb -rpx fifoctlr_icmw1_power_routed.rpx
  report_route_status -file fifoctlr_icmw1_route_status.rpt -pb fifoctlr_icmw1_route_status.pb
  report_clock_utilization -file fifoctlr_icmw1_clock_utilization_routed.rpt
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}


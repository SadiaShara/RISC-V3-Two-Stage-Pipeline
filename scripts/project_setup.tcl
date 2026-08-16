 1 # Setup tcl                                                                                                               2 # Sadia Tasnim Shara (22-48622-3)
  3 # Project 3B: Hazard-Free Two-Stage Pipelined RISC_V3
  4
  5 ##########################
  6 # Technology Setup
  7 ##########################
  8 #
  9 set TECH "sky130_cadence" ;# Options: "gpdk045 | sky130_cadence | sky130_open"
 10
 11 # Synthesis specific setup
 12 # Effect of these variable depends on the TECH used
 13 # No Effect for sky130_cadence
 14 set MULTIVT "true"
 15 set MBFF "false"
 16
 17 source -e -v $::env(REPO_ROOT)/util/tech/${TECH}.tcl
 18
 19
 20 ##########################
 21 # Design Setup
 22 ##########################
 23 set DESIGN_DIR "design_data"
 24 set DESIGN_NAME "$::env(TOP)"
 25 puts "TOP DESIGN SET TO: $DESIGN_NAME"
 26 set CLK_PORT "SYS_CLOCK"
 27 set CLK_PERIOD "17.0" ;# unit depends on pdk; for gpdk045 the unit is ns
 28
 29 set POWER_NET "VDD"
 30 set GROUND_NET "VSS"
  35 ##########################
 36 # Synthesis Setup
 37 ##########################
 38
 39 set SYNTH_EFFORT_GENERIC "high"
 40 set SYNTH_EFFORT_OPT "high"
 41 set SYNTH_INFO_LEVEL 7
 42 set SYNTH_LOW_POWER "false"
 43
 44 if { $var(step) == "synth" } {
 45     set_db / .use_scan_seqs_for_non_dft false
 46
 47     set CONSTRAINTS_FILE "[glob $DESIGN_DIR/*sdc]"
 48     set RTL_FILES "[exec python3 $::env(REPO_ROOT)/util/compile.py ../manifest.json syn]"
 49 }
 50
 51 ##########################
 52 # PnR Setup
 53 ##########################
 54 set PNR_INIT_NETLIST "$DESIGN_DIR/${DESIGN_NAME}_gate.v"
 55 set PNR_SDC "$DESIGN_DIR/${DESIGN_NAME}.sdc"
 56 set PNR_VIEW_DEF "$DESIGN_DIR/viewDefinition.tcl"
 57 set PNR_GND_NETS "VSS"
 58 set PNR_PWR_NETS "VDD"
 59 set PNR_MAX_ROUTE_LAYER "5"
 60 set PNR_FP_TCL "../floorplan/fp.tcl"
 61 set PNR_FP_DEF "../floorplan/fp.def"
 62 set PNR_FP_PRIORITY "TCL"    
 

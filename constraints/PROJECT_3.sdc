 1 # Project 3A timing constraints                                                                                           2 # CLK_PORT and CLK_PERIOD come from project_setup.tcl
  3
  4 # ------------------------------------------------------------
  5 # Clock
  6 # ------------------------------------------------------------
  7
  8 create_clock \
  9     -name CLK \
 10     -period $CLK_PERIOD \
 11     -waveform [list 0 [expr {$CLK_PERIOD / 2.0}]] \
 12     [get_ports $CLK_PORT]
 13
 14
 15 # ------------------------------------------------------------
 16 # Input-port groups
 17 # ------------------------------------------------------------
 18
 19 set CLOCK_INPUT [get_ports $CLK_PORT]
 20 set RESET_INPUT [get_ports FSM_ARESET]
 21
 22 # Remove the clock and asynchronous reset from normal data inputs
 23 set DATA_INPUTS \
 24     [remove_from_collection \
 25         [remove_from_collection \
 26             [all_inputs] \
 27             $CLOCK_INPUT] \
 28         $RESET_INPUT]
 30
 31 # ------------------------------------------------------------
 32 # Interface delays
 33 # ------------------------------------------------------------
 34
 35 set_input_delay \
 36     [expr {$CLK_PERIOD / 4.0}] \
 37     -clock [get_clocks CLK] \
 38     $DATA_INPUTS
 39
 40 set_output_delay \
 41     [expr {$CLK_PERIOD / 4.0}] \
 42     -clock [get_clocks CLK] \
 43     [all_outputs]
 44
 45
 46 # ------------------------------------------------------------
 47 # Asynchronous-reset timing exception
 48 # ------------------------------------------------------------
 49
 50 set_false_path \
 51     -from $RESET_INPUT             

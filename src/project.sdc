read_sdc $::env(SCRIPTS_DIR)/base.sdc

create_clock -period 10000.000 -name serial_clock -waveform {0.000 5000.000} -add [get_ports {uio_in[3]}]
set_clock_transition 0.1500 [get_clocks {serial_clock}]
set_clock_uncertainty 0.2500 serial_clock
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {serial_clock}]
# set_input_delay 1.5 -clock [get_clocks $::env(CLOCK_PORT)] {rst_n}
# set_input_delay 1.5 -clock [get_clocks $::env(CLOCK_PORT)] {ui_in}

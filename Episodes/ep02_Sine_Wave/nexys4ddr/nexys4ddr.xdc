# This file is specific for the Nexys 4 DDR board.

# Pin assignment
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { sys_clk_i }];  # CLK100MHZ
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { sys_rstn_i }]; # CPU_RESETN
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { aud_pwm_o }];  # AUD_PWM
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { aud_sd_o }];   # AUD_SD

# Clock definition
create_clock -name sys_clk -period 10.00 [get_ports {sys_clk_i}];
create_generated_clock -name ym2151_clk -source [get_pins {i_clk_rst/i_mmcm_adv/CLKOUT0}] -divide_by 64 [get_pins {i_clk_rst/pwm_cnt_r_reg[5]/Q}];

# Configuration Bank Voltage Select
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


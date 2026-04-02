SIM_OUT=simv
CPU_SIM_OUT=cpu_simv
CPU_LARGE_SIM_OUT=cpu_large_simv
APB_SIM_OUT=apb_simv

.PHONY: test test-cpu test-cpu-large test-apb clean

test:
	iverilog -g2012 -o $(SIM_OUT) src/mac.v src/matmul_accel.v tb/matmul_accel_tb.v
	vvp $(SIM_OUT)

test-cpu:
	iverilog -g2012 -o $(CPU_SIM_OUT) cpu5.v cpu5_tb.v
	vvp $(CPU_SIM_OUT)

test-cpu-large:
	iverilog -g2012 -o $(CPU_LARGE_SIM_OUT) \
		rtl/alu32.v rtl/regfile32.v rtl/control_unit.v rtl/forward_unit.v rtl/hazard_unit.v rtl/cpu5_system.v tb/cpu5_system_tb.v
	vvp $(CPU_LARGE_SIM_OUT)

test-apb:
	iverilog -g2012 -o $(APB_SIM_OUT) \
		rtl/apb_uart.v rtl/apb_spi.v rtl/apb_i2c.v rtl/apb_periph_subsys.v tb/apb_periph_subsys_tb.v
	vvp $(APB_SIM_OUT)

clean:
	rm -f $(SIM_OUT) $(CPU_SIM_OUT) $(CPU_LARGE_SIM_OUT) $(APB_SIM_OUT)

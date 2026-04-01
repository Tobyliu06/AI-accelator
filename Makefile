SIM_OUT=simv
CPU_SIM_OUT=cpu_simv

.PHONY: test test-cpu clean

test:
	iverilog -g2012 -o $(SIM_OUT) src/mac.v src/matmul_accel.v tb/matmul_accel_tb.v
	vvp $(SIM_OUT)

test-cpu:
	iverilog -g2012 -o $(CPU_SIM_OUT) cpu5.v cpu5_tb.v
	vvp $(CPU_SIM_OUT)

clean:
	rm -f $(SIM_OUT) $(CPU_SIM_OUT)

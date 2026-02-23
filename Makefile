SIM_OUT=simv

.PHONY: test clean

test:
	iverilog -g2012 -o $(SIM_OUT) src/mac.v src/matmul_accel.v tb/matmul_accel_tb.v
	vvp $(SIM_OUT)

clean:
	rm -f $(SIM_OUT)

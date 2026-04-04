`timescale 1ns/1ps

module cpu5_system_tb;
    reg clk;
    reg rst_n;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_r8;
    wire [31:0] dbg_r9;
    wire [31:0] dbg_r10;

    cpu5_system dut (
        .clk(clk),
        .rst_n(rst_n),
        .dbg_pc(dbg_pc),
        .dbg_r8(dbg_r8),
        .dbg_r9(dbg_r9),
        .dbg_r10(dbg_r10)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;

        // Program (MIPS-like):
        // addi t0, zero, 9
        // addi t1, zero, 3
        // add  t2, t0, t1       ; forwarding EX/MEM
        // sub  t0, t2, t1       ; forwarding MEM/WB
        // sw   t2, 0(zero)
        // lw   t1, 0(zero)
        // add  t2, t1, t0       ; load-use hazard -> stall 1 cycle
        // bne  t2, t0, +1       ; taken
        // addi t0, zero, 0      ; skipped
        // andi t0, t2, 15       ; t0 = 5

        dut.imem[0] = 32'h20080009;
        dut.imem[1] = 32'h20090003;
        dut.imem[2] = 32'h01095020;
        dut.imem[3] = 32'h01494022;
        dut.imem[4] = 32'hac0a0000;
        dut.imem[5] = 32'h8c090000;
        dut.imem[6] = 32'h01285020;
        dut.imem[7] = 32'h15480001;
        dut.imem[8] = 32'h20080000;
        dut.imem[9] = 32'h3148000f;

        #20 rst_n = 1'b1;
        #260;

        $display("r8=%0d r9=%0d r10=%0d mem0=%0d pc=0x%08x", dut.u_rf.regs[8], dut.u_rf.regs[9], dut.u_rf.regs[10], dut.dmem[0], dbg_pc);

        if ((dut.u_rf.regs[8] == 32'd5) && (dut.u_rf.regs[9] == 32'd12) && (dut.u_rf.regs[10] == 32'd21) && (dut.dmem[0] == 32'd12)) begin
            $display("PASS: larger 5-stage CPU system works with forwarding + load-use stall.");
        end else begin
            $display("FAIL: result mismatch.");
            $fatal(1);
        end

        $finish;
    end
endmodule

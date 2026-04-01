`timescale 1ns/1ps

module cpu5_tb;
    reg clk;
    reg rst_n;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_reg_t0;
    wire [31:0] dbg_reg_t1;

    cpu5_stage dut (
        .clk(clk),
        .rst_n(rst_n),
        .dbg_pc(dbg_pc),
        .dbg_reg_t0(dbg_reg_t0),
        .dbg_reg_t1(dbg_reg_t1)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;

        // Program:
        // addi $t0,$zero,5
        // addi $t1,$zero,7
        // nop
        // nop
        // add  $t0,$t0,$t1      => t0 = 12
        // sw   $t0,0($zero)
        // lw   $t1,0($zero)     => t1 = 12
        // nop
        // nop
        // beq  $t0,$t1, +1      => taken
        // addi $t0,$zero,0      => skipped
        // addi $t0,$t0,1        => t0 = 13

        dut.imem[0]  = 32'h20080005;
        dut.imem[1]  = 32'h20090007;
        dut.imem[2]  = 32'h00000000;
        dut.imem[3]  = 32'h00000000;
        dut.imem[4]  = 32'h01094020;
        dut.imem[5]  = 32'hac080000;
        dut.imem[6]  = 32'h8c090000;
        dut.imem[7]  = 32'h00000000;
        dut.imem[8]  = 32'h00000000;
        dut.imem[9]  = 32'h11090001;
        dut.imem[10] = 32'h20080000;
        dut.imem[11] = 32'h21080001;

        #20;
        rst_n = 1;

        #220;

        $display("t0=%0d t1=%0d mem0=%0d pc=0x%08x", dut.regs[8], dut.regs[9], dut.dmem[0], dbg_pc);

        if ((dut.regs[8] == 32'd13) && (dut.regs[9] == 32'd12) && (dut.dmem[0] == 32'd12)) begin
            $display("PASS: 5-stage CPU basic flow works.");
        end else begin
            $display("FAIL: unexpected results.");
            $fatal(1);
        end

        $finish;
    end
endmodule

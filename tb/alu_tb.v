`timescale 1ns/1ps

module alu_tb;
    reg  [7:0] a;
    reg  [7:0] b;
    reg  [2:0] op;
    wire [7:0] y;
    wire       zero;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .zero(zero)
    );

    task expect;
        input [7:0] exp_y;
        input       exp_zero;
        begin
            #1;
            if (y !== exp_y || zero !== exp_zero) begin
                $display("[FAIL] op=%b a=%0d b=%0d y=%0d zero=%b (expect y=%0d zero=%b)",
                         op, a, b, y, zero, exp_y, exp_zero);
                $finish;
            end
        end
    endtask

    initial begin
        // ADD
        a = 8'd5;  b = 8'd3;  op = 3'b000; expect(8'd8, 1'b0);
        // SUB
        a = 8'd5;  b = 8'd5;  op = 3'b001; expect(8'd0, 1'b1);
        // AND
        a = 8'hF0; b = 8'h0F; op = 3'b010; expect(8'h00, 1'b1);
        // OR
        a = 8'hF0; b = 8'h0F; op = 3'b011; expect(8'hFF, 1'b0);
        // XOR
        a = 8'hAA; b = 8'hFF; op = 3'b100; expect(8'h55, 1'b0);
        // SLL
        a = 8'd3;  b = 8'd2;  op = 3'b101; expect(8'd12, 1'b0);
        // SRL
        a = 8'd16; b = 8'd3;  op = 3'b110; expect(8'd2, 1'b0);
        // SLT signed: -1 < 1 -> 1
        a = 8'hFF; b = 8'h01; op = 3'b111; expect(8'd1, 1'b0);

        $display("[PASS] All ALU tests passed.");
        $finish;
    end
endmodule

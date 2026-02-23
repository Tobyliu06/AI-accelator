`timescale 1ns/1ps

module matmul_accel_tb;
    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [31:0] a_mat;
    reg  [31:0] b_mat;
    wire        busy;
    wire        done;
    wire [127:0] c_mat;

    matmul_accel dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_mat(a_mat),
        .b_mat(b_mat),
        .busy(busy),
        .done(done),
        .c_mat(c_mat)
    );

    always #5 clk = ~clk;

    task expect_c;
        input [31:0] c00;
        input [31:0] c01;
        input [31:0] c10;
        input [31:0] c11;
        begin
            if (c_mat[31:0] !== c00 || c_mat[63:32] !== c01 ||
                c_mat[95:64] !== c10 || c_mat[127:96] !== c11) begin
                $display("[FAIL] C mismatch: got {%0d,%0d,%0d,%0d}, expect {%0d,%0d,%0d,%0d}",
                    c_mat[31:0], c_mat[63:32], c_mat[95:64], c_mat[127:96],
                    c00, c01, c10, c11);
                $finish;
            end
        end
    endtask

    initial begin
        clk   = 0;
        rst_n = 0;
        start = 0;
        a_mat = 32'd0;
        b_mat = 32'd0;

        #20;
        rst_n = 1;

        // A = [ [1,2], [3,4] ]
        // B = [ [5,6], [7,8] ]
        // C = A*B = [ [19,22], [43,50] ]
        a_mat[7:0]   = 8'sd1;  // a00
        a_mat[15:8]  = 8'sd2;  // a01
        a_mat[23:16] = 8'sd3;  // a10
        a_mat[31:24] = 8'sd4;  // a11

        b_mat[7:0]   = 8'sd5;  // b00
        b_mat[15:8]  = 8'sd6;  // b01
        b_mat[23:16] = 8'sd7;  // b10
        b_mat[31:24] = 8'sd8;  // b11

        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait(done == 1'b1);
        #1;

        expect_c(32'd19, 32'd22, 32'd43, 32'd50);
        $display("[PASS] matmul_accel test passed.");
        $finish;
    end
endmodule

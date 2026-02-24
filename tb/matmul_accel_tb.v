`timescale 1ns/1ps

module matmul_accel_tb;
    reg          clk;
    reg          rst_n;
    reg          start;
    reg  [31:0]  a_mat;
    reg  [31:0]  b_mat;
    reg  [127:0] bias_mat;
    wire         busy;
    wire         done;
    wire [15:0]  cycle_count;
    wire [127:0] c_mat;

    matmul_accel #(
        .IN_W(8),
        .ACC_W(32),
        .DIM(2),
        .ADD_BIAS(1),
        .USE_RELU(1),
        .SATURATE(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_mat(a_mat),
        .b_mat(b_mat),
        .bias_mat(bias_mat),
        .busy(busy),
        .done(done),
        .cycle_count(cycle_count),
        .c_mat(c_mat)
    );

    always #5 clk = ~clk;

    task run_once;
        input [31:0] in_a;
        input [31:0] in_b;
        input [127:0] in_bias;
        begin
            a_mat = in_a;
            b_mat = in_b;
            bias_mat = in_bias;

            @(posedge clk);
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;

            wait(done == 1'b1);
            #1;
        end
    endtask

    task expect_c;
        input signed [31:0] c00;
        input signed [31:0] c01;
        input signed [31:0] c10;
        input signed [31:0] c11;
        begin
            if ($signed(c_mat[31:0]) !== c00 || $signed(c_mat[63:32]) !== c01 ||
                $signed(c_mat[95:64]) !== c10 || $signed(c_mat[127:96]) !== c11) begin
                $display("[FAIL] C mismatch: got {%0d,%0d,%0d,%0d}, expect {%0d,%0d,%0d,%0d}",
                    $signed(c_mat[31:0]), $signed(c_mat[63:32]), $signed(c_mat[95:64]), $signed(c_mat[127:96]),
                    c00, c01, c10, c11);
                $finish;
            end
        end
    endtask

    task expect_cycles;
        input [15:0] exp_cycles;
        begin
            if (cycle_count !== exp_cycles) begin
                $display("[FAIL] cycle_count=%0d expect=%0d", cycle_count, exp_cycles);
                $finish;
            end
        end
    endtask

    initial begin
        clk      = 0;
        rst_n    = 0;
        start    = 0;
        a_mat    = 32'd0;
        b_mat    = 32'd0;
        bias_mat = 128'd0;

        #20;
        rst_n = 1;

        // Case 1: baseline matmul + bias=0
        // A = [ [1,2], [3,4] ]
        // B = [ [5,6], [7,8] ]
        // C = [ [19,22], [43,50] ]
        run_once(
            {8'sd4, 8'sd3, 8'sd2, 8'sd1},
            {8'sd8, 8'sd7, 8'sd6, 8'sd5},
            128'd0
        );
        expect_c(32'sd19, 32'sd22, 32'sd43, 32'sd50);
        expect_cycles(16'd8);

        // Case 2: negative results should be ReLUed to zero
        // A = [ [1,-2], [3,-4] ]
        // B = [ [2,1], [1,2] ]
        // raw C = [ [0,-3], [2,-5] ]
        // after ReLU => [ [0,0], [2,0] ]
        run_once(
            {-8'sd4, 8'sd3, -8'sd2, 8'sd1},
            {8'sd2, 8'sd1, 8'sd1, 8'sd2},
            128'd0
        );
        expect_c(32'sd0, 32'sd0, 32'sd2, 32'sd0);
        expect_cycles(16'd8);

        // Case 3: bias add
        // Use identity A, and B as output basis. Then add bias [10,20,30,40]
        run_once(
            {8'sd1, 8'sd0, 8'sd0, 8'sd1},
            {8'sd4, 8'sd3, 8'sd2, 8'sd1},
            {32'sd40, 32'sd30, 32'sd20, 32'sd10}
        );
        // C = B + bias => [ [11,22], [33,44] ]
        expect_c(32'sd11, 32'sd22, 32'sd33, 32'sd44);
        expect_cycles(16'd8);

        $display("[PASS] matmul_accel multi-case test passed.");
        $finish;
    end
endmodule

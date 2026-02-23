module matmul_accel (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [31:0]  a_mat,
    input  wire [31:0]  b_mat,
    output reg          busy,
    output reg          done,
    output reg  [127:0] c_mat
);

reg [1:0] i;
reg [1:0] j;
reg [1:0] k;
reg signed [31:0] acc;

wire signed [7:0] a_elem;
wire signed [7:0] b_elem;
wire signed [31:0] acc_next;

mac #(
    .IN_W(8),
    .ACC_W(32)
) u_mac (
    .a(a_elem),
    .b(b_elem),
    .acc_in(acc),
    .acc_out(acc_next)
);

function [7:0] get_a;
    input [1:0] row;
    input [1:0] col;
    begin
        get_a = a_mat[((row*2 + col)*8) +: 8];
    end
endfunction

function [7:0] get_b;
    input [1:0] row;
    input [1:0] col;
    begin
        get_b = b_mat[((row*2 + col)*8) +: 8];
    end
endfunction

assign a_elem = get_a(i, k);
assign b_elem = get_b(k, j);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i     <= 2'd0;
        j     <= 2'd0;
        k     <= 2'd0;
        acc   <= 32'sd0;
        busy  <= 1'b0;
        done  <= 1'b0;
        c_mat <= 128'd0;
    end else begin
        done <= 1'b0;

        if (start && !busy) begin
            i    <= 2'd0;
            j    <= 2'd0;
            k    <= 2'd0;
            acc  <= 32'sd0;
            busy <= 1'b1;
        end else if (busy) begin
            acc <= acc_next;

            if (k == 2'd1) begin
                c_mat[((i*2 + j)*32) +: 32] <= acc_next;
                k <= 2'd0;
                acc <= 32'sd0;

                if (j == 2'd1) begin
                    j <= 2'd0;
                    if (i == 2'd1) begin
                        i    <= 2'd0;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        i <= i + 2'd1;
                    end
                end else begin
                    j <= j + 2'd1;
                end
            end else begin
                k <= k + 2'd1;
            end
        end
    end
end

endmodule

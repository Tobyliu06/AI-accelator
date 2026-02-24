module matmul_accel #(
    parameter IN_W   = 8,
    parameter ACC_W  = 32,
    parameter DIM    = 2,
    parameter ADD_BIAS = 1,
    parameter USE_RELU = 1,
    parameter SATURATE = 1
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,
    input  wire [DIM*DIM*IN_W-1:0]      a_mat,
    input  wire [DIM*DIM*IN_W-1:0]      b_mat,
    input  wire [DIM*DIM*ACC_W-1:0]     bias_mat,
    output reg                          busy,
    output reg                          done,
    output reg  [15:0]                  cycle_count,
    output reg  [DIM*DIM*ACC_W-1:0]     c_mat
);

localparam IDX_W = 2;

reg [IDX_W-1:0] i;
reg [IDX_W-1:0] j;
reg [IDX_W-1:0] k;
reg signed [ACC_W-1:0] acc;

wire signed [IN_W-1:0] a_elem;
wire signed [IN_W-1:0] b_elem;
wire signed [ACC_W-1:0] acc_next;
wire signed [ACC_W-1:0] bias_elem;
wire signed [ACC_W-1:0] out_pre_act;
wire signed [ACC_W-1:0] out_post_act;

mac #(
    .IN_W(IN_W),
    .ACC_W(ACC_W)
) u_mac (
    .a(a_elem),
    .b(b_elem),
    .acc_in(acc),
    .acc_out(acc_next)
);

function [IN_W-1:0] get_a;
    input [IDX_W-1:0] row;
    input [IDX_W-1:0] col;
    begin
        get_a = a_mat[((row*DIM + col)*IN_W) +: IN_W];
    end
endfunction

function [IN_W-1:0] get_b;
    input [IDX_W-1:0] row;
    input [IDX_W-1:0] col;
    begin
        get_b = b_mat[((row*DIM + col)*IN_W) +: IN_W];
    end
endfunction

function [ACC_W-1:0] get_bias;
    input [IDX_W-1:0] row;
    input [IDX_W-1:0] col;
    begin
        get_bias = bias_mat[((row*DIM + col)*ACC_W) +: ACC_W];
    end
endfunction

function [ACC_W-1:0] clamp_acc;
    input signed [ACC_W:0] value_ext;
    reg signed [ACC_W:0] max_ext;
    reg signed [ACC_W:0] min_ext;
    begin
        max_ext = {1'b0, 1'b0, {(ACC_W-1){1'b1}}};
        min_ext = {1'b1, 1'b1, {(ACC_W-1){1'b0}}};

        if (!SATURATE) begin
            clamp_acc = value_ext[ACC_W-1:0];
        end else if (value_ext > max_ext) begin
            clamp_acc = {1'b0, {(ACC_W-1){1'b1}}};
        end else if (value_ext < min_ext) begin
            clamp_acc = {1'b1, {(ACC_W-1){1'b0}}};
        end else begin
            clamp_acc = value_ext[ACC_W-1:0];
        end
    end
endfunction

assign a_elem = get_a(i, k);
assign b_elem = get_b(k, j);
assign bias_elem = get_bias(i, j);
assign out_pre_act = ADD_BIAS ? clamp_acc($signed({acc_next[ACC_W-1], acc_next}) + $signed({bias_elem[ACC_W-1], bias_elem})) : acc_next;
assign out_post_act = (USE_RELU && out_pre_act[ACC_W-1]) ? {ACC_W{1'b0}} : out_pre_act;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i           <= {IDX_W{1'b0}};
        j           <= {IDX_W{1'b0}};
        k           <= {IDX_W{1'b0}};
        acc         <= {ACC_W{1'b0}};
        busy        <= 1'b0;
        done        <= 1'b0;
        cycle_count <= 16'd0;
        c_mat       <= {(DIM*DIM*ACC_W){1'b0}};
    end else begin
        done <= 1'b0;

        if (start && !busy) begin
            i           <= {IDX_W{1'b0}};
            j           <= {IDX_W{1'b0}};
            k           <= {IDX_W{1'b0}};
            acc         <= {ACC_W{1'b0}};
            busy        <= 1'b1;
            cycle_count <= 16'd0;
            c_mat       <= {(DIM*DIM*ACC_W){1'b0}};
        end else if (busy) begin
            cycle_count <= cycle_count + 16'd1;
            acc <= acc_next;

            if (k == (DIM-1)) begin
                c_mat[((i*DIM + j)*ACC_W) +: ACC_W] <= out_post_act;
                k <= {IDX_W{1'b0}};
                acc <= {ACC_W{1'b0}};

                if (j == (DIM-1)) begin
                    j <= {IDX_W{1'b0}};
                    if (i == (DIM-1)) begin
                        i    <= {IDX_W{1'b0}};
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        i <= i + 1'b1;
                    end
                end else begin
                    j <= j + 1'b1;
                end
            end else begin
                k <= k + 1'b1;
            end
        end
    end
end

endmodule

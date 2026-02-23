module mac #(
    parameter IN_W  = 8,
    parameter ACC_W = 32
) (
    input  wire signed [IN_W-1:0]  a,
    input  wire signed [IN_W-1:0]  b,
    input  wire signed [ACC_W-1:0] acc_in,
    output wire signed [ACC_W-1:0] acc_out
);

assign acc_out = acc_in + (a * b);

endmodule

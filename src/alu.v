module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] op,
    output reg  [7:0] y,
    output wire       zero
);

always @(*) begin
    case (op)
        3'b000: y = a + b;
        3'b001: y = a - b;
        3'b010: y = a & b;
        3'b011: y = a | b;
        3'b100: y = a ^ b;
        3'b101: y = a << b[2:0];
        3'b110: y = a >> b[2:0];
        3'b111: y = ($signed(a) < $signed(b)) ? 8'd1 : 8'd0;
        default: y = 8'd0;
    endcase
end

assign zero = (y == 8'd0);

endmodule

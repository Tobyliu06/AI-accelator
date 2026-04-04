module apb_i2c (
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [11:0] paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,
    output wire        pslverr,
    output reg         i2c_start,
    output reg  [6:0]  i2c_addr,
    output reg  [7:0]  i2c_data
);
    reg busy;
    reg ack;
    reg [15:0] scl_div;

    wire wr_en = psel && penable && pwrite;

    assign pready = 1'b1;
    assign pslverr = 1'b0;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            i2c_start <= 1'b0;
            i2c_addr <= 7'd0;
            i2c_data <= 8'd0;
            busy <= 1'b0;
            ack <= 1'b0;
            scl_div <= 16'd100;
        end else begin
            i2c_start <= 1'b0;
            busy <= 1'b0;
            if (wr_en) begin
                case (paddr[5:2])
                    4'h0: begin
                        i2c_addr <= pwdata[6:0];
                        i2c_data <= pwdata[15:8];
                        i2c_start <= 1'b1;
                        busy <= 1'b1;
                        ack <= 1'b1;
                    end
                    4'h2: scl_div <= pwdata[15:0];
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (paddr[5:2])
            4'h0: prdata = {16'd0, i2c_data, 1'b0, i2c_addr};
            4'h1: prdata = {30'd0, busy, ack};
            4'h2: prdata = {16'd0, scl_div};
            default: prdata = 32'd0;
        endcase
    end
endmodule

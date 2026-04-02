module apb_spi (
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
    output reg         spi_start,
    output reg  [7:0]  spi_tx_data
);
    reg [7:0] spi_rx_data;
    reg [15:0] clk_div;
    reg cpol;
    reg cpha;
    reg busy;

    wire wr_en = psel && penable && pwrite;

    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            spi_rx_data <= 8'd0;
            clk_div <= 16'd4;
            cpol <= 1'b0;
            cpha <= 1'b0;
            busy <= 1'b0;
            spi_start <= 1'b0;
            spi_tx_data <= 8'd0;
        end else begin
            spi_start <= 1'b0;
            busy <= 1'b0;
            if (wr_en) begin
                case (paddr[5:2])
                    4'h0: begin
                        spi_tx_data <= pwdata[7:0];
                        spi_start <= 1'b1;
                        busy <= 1'b1;
                        spi_rx_data <= pwdata[7:0] ^ 8'hA5; // demo loopback transform
                    end
                    4'h2: begin
                        cpol <= pwdata[0];
                        cpha <= pwdata[1];
                    end
                    4'h3: clk_div <= pwdata[15:0];
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (paddr[5:2])
            4'h0: prdata = {24'd0, spi_rx_data};
            4'h1: prdata = {31'd0, busy};
            4'h2: prdata = {30'd0, cpha, cpol};
            4'h3: prdata = {16'd0, clk_div};
            default: prdata = 32'd0;
        endcase
    end
endmodule

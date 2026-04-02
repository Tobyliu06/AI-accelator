module apb_uart (
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
    output reg         uart_tx_start,
    output reg  [7:0]  uart_tx_data
);
    reg [7:0] rx_data;
    reg       rx_valid;
    reg       tx_busy;
    reg [31:0] baud_div;

    wire wr_en = psel && penable && pwrite;
    wire rd_en = psel && penable && !pwrite;

    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            rx_data <= 8'd0;
            rx_valid <= 1'b0;
            tx_busy <= 1'b0;
            baud_div <= 32'd434;
            uart_tx_start <= 1'b0;
            uart_tx_data <= 8'd0;
        end else begin
            uart_tx_start <= 1'b0;
            tx_busy <= 1'b0; // demo behavior: 1-cycle busy pulse

            if (wr_en) begin
                case (paddr[5:2])
                    4'h0: begin
                        uart_tx_data <= pwdata[7:0];
                        uart_tx_start <= 1'b1;
                        tx_busy <= 1'b1;
                    end
                    4'h3: baud_div <= pwdata;
                    default: ;
                endcase
            end

            if (rd_en && (paddr[5:2] == 4'h1)) begin
                rx_valid <= 1'b0; // clear on status read for demo
            end
        end
    end

    always @(*) begin
        case (paddr[5:2])
            4'h0: prdata = {24'd0, rx_data};
            4'h1: prdata = {30'd0, tx_busy, rx_valid};
            4'h3: prdata = baud_div;
            default: prdata = 32'd0;
        endcase
    end
endmodule

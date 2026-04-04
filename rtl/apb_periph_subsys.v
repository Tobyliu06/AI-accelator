module apb_periph_subsys (
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,
    output reg         pslverr,

    output wire        uart_tx_start,
    output wire [7:0]  uart_tx_data,
    output wire        spi_start,
    output wire [7:0]  spi_tx_data,
    output wire        i2c_start,
    output wire [6:0]  i2c_addr,
    output wire [7:0]  i2c_data
);
    localparam SEL_UART = 4'h0;
    localparam SEL_SPI  = 4'h1;
    localparam SEL_I2C  = 4'h2;

    wire sel_uart = psel && (paddr[15:12] == SEL_UART);
    wire sel_spi  = psel && (paddr[15:12] == SEL_SPI);
    wire sel_i2c  = psel && (paddr[15:12] == SEL_I2C);

    wire [31:0] uart_prdata, spi_prdata, i2c_prdata;
    wire uart_pready, spi_pready, i2c_pready;
    wire uart_pslverr, spi_pslverr, i2c_pslverr;

    apb_uart u_uart (
        .pclk(pclk), .presetn(presetn), .psel(sel_uart), .penable(penable),
        .pwrite(pwrite), .paddr(paddr[11:0]), .pwdata(pwdata),
        .prdata(uart_prdata), .pready(uart_pready), .pslverr(uart_pslverr),
        .uart_tx_start(uart_tx_start), .uart_tx_data(uart_tx_data)
    );

    apb_spi u_spi (
        .pclk(pclk), .presetn(presetn), .psel(sel_spi), .penable(penable),
        .pwrite(pwrite), .paddr(paddr[11:0]), .pwdata(pwdata),
        .prdata(spi_prdata), .pready(spi_pready), .pslverr(spi_pslverr),
        .spi_start(spi_start), .spi_tx_data(spi_tx_data)
    );

    apb_i2c u_i2c (
        .pclk(pclk), .presetn(presetn), .psel(sel_i2c), .penable(penable),
        .pwrite(pwrite), .paddr(paddr[11:0]), .pwdata(pwdata),
        .prdata(i2c_prdata), .pready(i2c_pready), .pslverr(i2c_pslverr),
        .i2c_start(i2c_start), .i2c_addr(i2c_addr), .i2c_data(i2c_data)
    );

    always @(*) begin
        prdata = 32'd0;
        pready = 1'b1;
        pslverr = 1'b0;

        if (sel_uart) begin
            prdata = uart_prdata;
            pready = uart_pready;
            pslverr = uart_pslverr;
        end else if (sel_spi) begin
            prdata = spi_prdata;
            pready = spi_pready;
            pslverr = spi_pslverr;
        end else if (sel_i2c) begin
            prdata = i2c_prdata;
            pready = i2c_pready;
            pslverr = i2c_pslverr;
        end else if (psel) begin
            pslverr = 1'b1;
        end
    end
endmodule

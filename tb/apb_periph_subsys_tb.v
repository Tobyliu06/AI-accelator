`timescale 1ns/1ps

module apb_periph_subsys_tb;
    reg clk;
    reg rst_n;
    reg psel;
    reg penable;
    reg pwrite;
    reg [31:0] paddr;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    wire pready;
    wire pslverr;

    wire uart_tx_start;
    wire [7:0] uart_tx_data;
    wire spi_start;
    wire [7:0] spi_tx_data;
    wire i2c_start;
    wire [6:0] i2c_addr;
    wire [7:0] i2c_data;

    apb_periph_subsys dut (
        .pclk(clk), .presetn(rst_n),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready), .pslverr(pslverr),
        .uart_tx_start(uart_tx_start), .uart_tx_data(uart_tx_data),
        .spi_start(spi_start), .spi_tx_data(spi_tx_data),
        .i2c_start(i2c_start), .i2c_addr(i2c_addr), .i2c_data(i2c_data)
    );

    always #5 clk = ~clk;

    task apb_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        psel <= 1'b1;
        penable <= 1'b0;
        pwrite <= 1'b1;
        paddr <= addr;
        pwdata <= data;

        @(posedge clk);
        penable <= 1'b1;

        @(posedge clk);
        psel <= 1'b0;
        penable <= 1'b0;
        pwrite <= 1'b0;
        paddr <= 32'd0;
        pwdata <= 32'd0;
    end
    endtask

    task apb_read(input [31:0] addr, output [31:0] data);
    begin
        @(posedge clk);
        psel <= 1'b1;
        penable <= 1'b0;
        pwrite <= 1'b0;
        paddr <= addr;

        @(posedge clk);
        penable <= 1'b1;

        @(posedge clk);
        data = prdata;
        psel <= 1'b0;
        penable <= 1'b0;
        paddr <= 32'd0;
    end
    endtask

    reg [31:0] rdata;
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        paddr = 32'd0;
        pwdata = 32'd0;

        #20 rst_n = 1'b1;

        // UART base: 0x0000_xxxx
        apb_write(32'h0000_0000, 32'h0000_005A);
        if (!uart_tx_start || uart_tx_data != 8'h5A) begin
            $display("FAIL: UART write path");
            $fatal(1);
        end

        apb_write(32'h0000_000C, 32'd868);
        apb_read(32'h0000_000C, rdata);
        if (rdata != 32'd868) begin
            $display("FAIL: UART baud register readback");
            $fatal(1);
        end

        // SPI base: 0x0000_1xxx
        apb_write(32'h0000_1000, 32'h0000_003C);
        if (!spi_start || spi_tx_data != 8'h3C) begin
            $display("FAIL: SPI write path");
            $fatal(1);
        end

        apb_read(32'h0000_1000, rdata);
        if (rdata[7:0] != (8'h3C ^ 8'hA5)) begin
            $display("FAIL: SPI RX register");
            $fatal(1);
        end

        // I2C base: 0x0000_2xxx
        apb_write(32'h0000_2000, 32'h0000_A255); // data=0xA2, addr=0x55
        if (!i2c_start || i2c_addr != 7'h55 || i2c_data != 8'hA2) begin
            $display("FAIL: I2C write path");
            $fatal(1);
        end

        apb_read(32'h0000_2004, rdata);
        if (rdata[0] != 1'b1) begin
            $display("FAIL: I2C ACK bit");
            $fatal(1);
        end

        // invalid region should assert PSLVERR
        @(posedge clk);
        psel <= 1'b1;
        penable <= 1'b1;
        pwrite <= 1'b0;
        paddr <= 32'h0000_F000;
        @(posedge clk);
        if (!pslverr) begin
            $display("FAIL: decode PSLVERR");
            $fatal(1);
        end

        $display("PASS: APB subsystem connects UART/SPI/I2C.");
        $finish;
    end
endmodule

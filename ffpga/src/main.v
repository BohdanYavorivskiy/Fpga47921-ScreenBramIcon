// Pmod LCD 0.96" (ST7735S, 160x80, 4-wire SPI) showing a 128x64 colour
// bitmap that is read from the on-chip BRAMs, one byte per pixel (RGB332: bits
// 7:5 red, 4:2 green, 1:0 blue; 0 = black, 255 = white). The 16/8 pixel frame around it stays black.
// The picture is not generated here: it is the BRAM initial data loaded into the
// project (Go Configure, BRAM data import; 8192 lines, row by row).
//
//   GPIO15 : panel reset              GPIO8/9/10/11 : CS / MOSI / DC / SCLK
//
// Clocking: the on-chip oscillator runs at 50 MHz and post-divider OUT0 halves
// it, so i_clk is 25 MHz. The clock source must be selected in CLK MUX0 in the
// project (register setting, not RTL) and i_clk mapped to GLOBAL_CLK_MUX_OUT[0].
//
// lcd_ctrl (spi_master + lcd_init_rom) is the panel driver, bram_bitmap turns
// the screen position into a BRAM address and picks the byte that comes back.
// All four BRAMs hold the same address; each one stores 16 of the 64 image rows
// (see bram_bitmap for the layout). The o_bram*/i_bram* ports below are the BRAM
// control, address and data buses, mapped to the HBRAM pins in the IO planner.
(* top *) module main(
    (* clkbuf_inhibit *) input i_clk,
    output o_osc_en,
    output o_osc_mode,
    output o_postdiv0_en,
    output o_postdiv0_sel0,
    output o_postdiv0_sel1,
    output o_postdiv0_sel2,
    output o_tft_reset,
    output o_tft_reset_oe,
    output o_tft_cs,
    output o_tft_cs_oe,
    output o_tft_dc,
    output o_tft_dc_oe,
    output o_tft_mosi,
    output o_tft_mosi_oe,
    output o_tft_clk,
    output o_tft_clk_oe,
    output o_bram0_sram0_1_en,
    output [1:0] o_bram0_sram0_1_ratio,
    output [8:0] o_bram0_sram0_1_rd_addr,
    output o_bram0_sram0_1_rd_clken,
    output o_bram0_sram0_1_rd_clkinv,
    output o_bram0_sram0_1_rd_en,
    output [8:0] o_bram0_sram0_1_wr_addr,
    output o_bram0_sram0_1_wr_clken,
    output o_bram0_sram0_1_wr_clkinv,
    input  [7:0] i_bram0_sram0_rd_data,
    output [7:0] o_bram0_sram0_wr_data,
    output o_bram0_sram0_wr_en,
    input  [7:0] i_bram0_sram1_rd_data,
    output [7:0] o_bram0_sram1_wr_data,
    output o_bram0_sram1_wr_en,
    output o_bram0_sram2_3_en,
    output [1:0] o_bram0_sram2_3_ratio,
    output [8:0] o_bram0_sram2_3_rd_addr,
    output o_bram0_sram2_3_rd_clken,
    output o_bram0_sram2_3_rd_clkinv,
    output o_bram0_sram2_3_rd_en,
    output [8:0] o_bram0_sram2_3_wr_addr,
    output o_bram0_sram2_3_wr_clken,
    output o_bram0_sram2_3_wr_clkinv,
    input  [7:0] i_bram0_sram2_rd_data,
    output [7:0] o_bram0_sram2_wr_data,
    output o_bram0_sram2_wr_en,
    input  [7:0] i_bram0_sram3_rd_data,
    output [7:0] o_bram0_sram3_wr_data,
    output o_bram0_sram3_wr_en,
    output o_bram1_sram0_1_en,
    output [1:0] o_bram1_sram0_1_ratio,
    output [8:0] o_bram1_sram0_1_rd_addr,
    output o_bram1_sram0_1_rd_clken,
    output o_bram1_sram0_1_rd_clkinv,
    output o_bram1_sram0_1_rd_en,
    output [8:0] o_bram1_sram0_1_wr_addr,
    output o_bram1_sram0_1_wr_clken,
    output o_bram1_sram0_1_wr_clkinv,
    input  [7:0] i_bram1_sram0_rd_data,
    output [7:0] o_bram1_sram0_wr_data,
    output o_bram1_sram0_wr_en,
    input  [7:0] i_bram1_sram1_rd_data,
    output [7:0] o_bram1_sram1_wr_data,
    output o_bram1_sram1_wr_en,
    output o_bram1_sram2_3_en,
    output [1:0] o_bram1_sram2_3_ratio,
    output [8:0] o_bram1_sram2_3_rd_addr,
    output o_bram1_sram2_3_rd_clken,
    output o_bram1_sram2_3_rd_clkinv,
    output o_bram1_sram2_3_rd_en,
    output [8:0] o_bram1_sram2_3_wr_addr,
    output o_bram1_sram2_3_wr_clken,
    output o_bram1_sram2_3_wr_clkinv,
    input  [7:0] i_bram1_sram2_rd_data,
    output [7:0] o_bram1_sram2_wr_data,
    output o_bram1_sram2_wr_en,
    input  [7:0] i_bram1_sram3_rd_data,
    output [7:0] o_bram1_sram3_wr_data,
    output o_bram1_sram3_wr_en,
    output o_bram2_sram0_1_en,
    output [1:0] o_bram2_sram0_1_ratio,
    output [8:0] o_bram2_sram0_1_rd_addr,
    output o_bram2_sram0_1_rd_clken,
    output o_bram2_sram0_1_rd_clkinv,
    output o_bram2_sram0_1_rd_en,
    output [8:0] o_bram2_sram0_1_wr_addr,
    output o_bram2_sram0_1_wr_clken,
    output o_bram2_sram0_1_wr_clkinv,
    input  [7:0] i_bram2_sram0_rd_data,
    output [7:0] o_bram2_sram0_wr_data,
    output o_bram2_sram0_wr_en,
    input  [7:0] i_bram2_sram1_rd_data,
    output [7:0] o_bram2_sram1_wr_data,
    output o_bram2_sram1_wr_en,
    output o_bram2_sram2_3_en,
    output [1:0] o_bram2_sram2_3_ratio,
    output [8:0] o_bram2_sram2_3_rd_addr,
    output o_bram2_sram2_3_rd_clken,
    output o_bram2_sram2_3_rd_clkinv,
    output o_bram2_sram2_3_rd_en,
    output [8:0] o_bram2_sram2_3_wr_addr,
    output o_bram2_sram2_3_wr_clken,
    output o_bram2_sram2_3_wr_clkinv,
    input  [7:0] i_bram2_sram2_rd_data,
    output [7:0] o_bram2_sram2_wr_data,
    output o_bram2_sram2_wr_en,
    input  [7:0] i_bram2_sram3_rd_data,
    output [7:0] o_bram2_sram3_wr_data,
    output o_bram2_sram3_wr_en,
    output o_bram3_sram0_1_en,
    output [1:0] o_bram3_sram0_1_ratio,
    output [8:0] o_bram3_sram0_1_rd_addr,
    output o_bram3_sram0_1_rd_clken,
    output o_bram3_sram0_1_rd_clkinv,
    output o_bram3_sram0_1_rd_en,
    output [8:0] o_bram3_sram0_1_wr_addr,
    output o_bram3_sram0_1_wr_clken,
    output o_bram3_sram0_1_wr_clkinv,
    input  [7:0] i_bram3_sram0_rd_data,
    output [7:0] o_bram3_sram0_wr_data,
    output o_bram3_sram0_wr_en,
    input  [7:0] i_bram3_sram1_rd_data,
    output [7:0] o_bram3_sram1_wr_data,
    output o_bram3_sram1_wr_en,
    output o_bram3_sram2_3_en,
    output [1:0] o_bram3_sram2_3_ratio,
    output [8:0] o_bram3_sram2_3_rd_addr,
    output o_bram3_sram2_3_rd_clken,
    output o_bram3_sram2_3_rd_clkinv,
    output o_bram3_sram2_3_rd_en,
    output [8:0] o_bram3_sram2_3_wr_addr,
    output o_bram3_sram2_3_wr_clken,
    output o_bram3_sram2_3_wr_clkinv,
    input  [7:0] i_bram3_sram2_rd_data,
    output [7:0] o_bram3_sram2_wr_data,
    output o_bram3_sram2_wr_en,
    input  [7:0] i_bram3_sram3_rd_data,
    output [7:0] o_bram3_sram3_wr_data,
    output o_bram3_sram3_wr_en
);
    // On-chip oscillator: 50 MHz mode, post-divider OUT0 = 50/2 = 25 MHz (DIV_SEL=001)
    assign o_osc_en        = 1'b1;
    assign o_osc_mode      = 1'b1;
    assign o_postdiv0_en   = 1'b1;
    assign o_postdiv0_sel0 = 1'b1;
    assign o_postdiv0_sel1 = 1'b0;
    assign o_postdiv0_sel2 = 1'b0;

    assign o_tft_reset_oe  = 1'b1;     // every LCD pin is driven, never sensed
    assign o_tft_cs_oe     = 1'b1;
    assign o_tft_dc_oe     = 1'b1;
    assign o_tft_mosi_oe   = 1'b1;
    assign o_tft_clk_oe    = 1'b1;

    wire [7:0]   x;
    wire [6:0]   y;
    wire [7:0]   pix;
    wire         inside;
    wire         bm_wr_en;
    wire [8:0]   bm_wr_addr, bm_rd_addr;
    wire [127:0] bm_wr_data;
    // Image part c (rows 16c..16c+15, file bytes 2048c..2048c+2047) is physically in BRAM c^1:
    // the imported data is laid out 2-1-4-3 relative to the IO-table order bram0..3.
    wire [127:0] bm_rd_data = {i_bram2_sram3_rd_data, i_bram2_sram2_rd_data, i_bram2_sram1_rd_data, i_bram2_sram0_rd_data, i_bram3_sram3_rd_data, i_bram3_sram2_rd_data, i_bram3_sram1_rd_data, i_bram3_sram0_rd_data, i_bram0_sram3_rd_data, i_bram0_sram2_rd_data, i_bram0_sram1_rd_data, i_bram0_sram0_rd_data, i_bram1_sram3_rd_data, i_bram1_sram2_rd_data, i_bram1_sram1_rd_data, i_bram1_sram0_rd_data};

    bram_bitmap #(.FILL(0)) u_bm (
        .clk(i_clk),
        .i_x(x), .i_y(y),
        .o_pix(pix), .o_inside(inside),
        .o_wr_addr(bm_wr_addr), .o_wr_en(bm_wr_en), .o_wr_data(bm_wr_data),
        .o_rd_addr(bm_rd_addr), .i_rd_data(bm_rd_data)
    );

    // Inside the bitmap window: RGB332 byte -> RGB565 by bit replication (so 0x00
    // stays black and 0xFF becomes full white); black outside.
    wire [15:0] color = inside ? {pix[7:5], pix[7:6], pix[4:2], pix[4:2], pix[1:0], pix[1:0], pix[1]}
                               : 16'h0000;

    lcd_ctrl #(.RD_WAIT(4'd4)) u_lcd (
        .clk(i_clk),
        .i_color(color),
        .o_x(x), .o_y(y),
        .o_reset(o_tft_reset),
        .o_cs(o_tft_cs),
        .o_dc(o_tft_dc),
        .o_mosi(o_tft_mosi),
        .o_sclk(o_tft_clk)
    );

    // ---- BRAM control: all four BRAMs, 512 x 8, all slices on ----
    // The BRAM read/write clocks are not ports: i_clk is mapped straight to the
    // HBRAM clock outputs in the IO planner (see the tool's BRAM FIFO example).
    assign o_bram0_sram0_1_en = 1'b1;
    assign o_bram0_sram0_1_ratio = 2'b00;
    assign o_bram0_sram0_1_rd_addr = bm_rd_addr;
    assign o_bram0_sram0_1_rd_clken = 1'b1;
    assign o_bram0_sram0_1_rd_clkinv = 1'b0;
    assign o_bram0_sram0_1_rd_en = 1'b1;
    assign o_bram0_sram0_1_wr_addr = bm_wr_addr;
    assign o_bram0_sram0_1_wr_clken = 1'b1;
    assign o_bram0_sram0_1_wr_clkinv = 1'b0;
    assign o_bram0_sram0_wr_data = bm_wr_data[32 +: 8];
    assign o_bram0_sram0_wr_en = bm_wr_en;
    assign o_bram0_sram1_wr_data = bm_wr_data[40 +: 8];
    assign o_bram0_sram1_wr_en = bm_wr_en;
    assign o_bram0_sram2_3_en = 1'b1;
    assign o_bram0_sram2_3_ratio = 2'b00;
    assign o_bram0_sram2_3_rd_addr = bm_rd_addr;
    assign o_bram0_sram2_3_rd_clken = 1'b1;
    assign o_bram0_sram2_3_rd_clkinv = 1'b0;
    assign o_bram0_sram2_3_rd_en = 1'b1;
    assign o_bram0_sram2_3_wr_addr = bm_wr_addr;
    assign o_bram0_sram2_3_wr_clken = 1'b1;
    assign o_bram0_sram2_3_wr_clkinv = 1'b0;
    assign o_bram0_sram2_wr_data = bm_wr_data[48 +: 8];
    assign o_bram0_sram2_wr_en = bm_wr_en;
    assign o_bram0_sram3_wr_data = bm_wr_data[56 +: 8];
    assign o_bram0_sram3_wr_en = bm_wr_en;
    assign o_bram1_sram0_1_en = 1'b1;
    assign o_bram1_sram0_1_ratio = 2'b00;
    assign o_bram1_sram0_1_rd_addr = bm_rd_addr;
    assign o_bram1_sram0_1_rd_clken = 1'b1;
    assign o_bram1_sram0_1_rd_clkinv = 1'b0;
    assign o_bram1_sram0_1_rd_en = 1'b1;
    assign o_bram1_sram0_1_wr_addr = bm_wr_addr;
    assign o_bram1_sram0_1_wr_clken = 1'b1;
    assign o_bram1_sram0_1_wr_clkinv = 1'b0;
    assign o_bram1_sram0_wr_data = bm_wr_data[0 +: 8];
    assign o_bram1_sram0_wr_en = bm_wr_en;
    assign o_bram1_sram1_wr_data = bm_wr_data[8 +: 8];
    assign o_bram1_sram1_wr_en = bm_wr_en;
    assign o_bram1_sram2_3_en = 1'b1;
    assign o_bram1_sram2_3_ratio = 2'b00;
    assign o_bram1_sram2_3_rd_addr = bm_rd_addr;
    assign o_bram1_sram2_3_rd_clken = 1'b1;
    assign o_bram1_sram2_3_rd_clkinv = 1'b0;
    assign o_bram1_sram2_3_rd_en = 1'b1;
    assign o_bram1_sram2_3_wr_addr = bm_wr_addr;
    assign o_bram1_sram2_3_wr_clken = 1'b1;
    assign o_bram1_sram2_3_wr_clkinv = 1'b0;
    assign o_bram1_sram2_wr_data = bm_wr_data[16 +: 8];
    assign o_bram1_sram2_wr_en = bm_wr_en;
    assign o_bram1_sram3_wr_data = bm_wr_data[24 +: 8];
    assign o_bram1_sram3_wr_en = bm_wr_en;
    assign o_bram2_sram0_1_en = 1'b1;
    assign o_bram2_sram0_1_ratio = 2'b00;
    assign o_bram2_sram0_1_rd_addr = bm_rd_addr;
    assign o_bram2_sram0_1_rd_clken = 1'b1;
    assign o_bram2_sram0_1_rd_clkinv = 1'b0;
    assign o_bram2_sram0_1_rd_en = 1'b1;
    assign o_bram2_sram0_1_wr_addr = bm_wr_addr;
    assign o_bram2_sram0_1_wr_clken = 1'b1;
    assign o_bram2_sram0_1_wr_clkinv = 1'b0;
    assign o_bram2_sram0_wr_data = bm_wr_data[96 +: 8];
    assign o_bram2_sram0_wr_en = bm_wr_en;
    assign o_bram2_sram1_wr_data = bm_wr_data[104 +: 8];
    assign o_bram2_sram1_wr_en = bm_wr_en;
    assign o_bram2_sram2_3_en = 1'b1;
    assign o_bram2_sram2_3_ratio = 2'b00;
    assign o_bram2_sram2_3_rd_addr = bm_rd_addr;
    assign o_bram2_sram2_3_rd_clken = 1'b1;
    assign o_bram2_sram2_3_rd_clkinv = 1'b0;
    assign o_bram2_sram2_3_rd_en = 1'b1;
    assign o_bram2_sram2_3_wr_addr = bm_wr_addr;
    assign o_bram2_sram2_3_wr_clken = 1'b1;
    assign o_bram2_sram2_3_wr_clkinv = 1'b0;
    assign o_bram2_sram2_wr_data = bm_wr_data[112 +: 8];
    assign o_bram2_sram2_wr_en = bm_wr_en;
    assign o_bram2_sram3_wr_data = bm_wr_data[120 +: 8];
    assign o_bram2_sram3_wr_en = bm_wr_en;
    assign o_bram3_sram0_1_en = 1'b1;
    assign o_bram3_sram0_1_ratio = 2'b00;
    assign o_bram3_sram0_1_rd_addr = bm_rd_addr;
    assign o_bram3_sram0_1_rd_clken = 1'b1;
    assign o_bram3_sram0_1_rd_clkinv = 1'b0;
    assign o_bram3_sram0_1_rd_en = 1'b1;
    assign o_bram3_sram0_1_wr_addr = bm_wr_addr;
    assign o_bram3_sram0_1_wr_clken = 1'b1;
    assign o_bram3_sram0_1_wr_clkinv = 1'b0;
    assign o_bram3_sram0_wr_data = bm_wr_data[64 +: 8];
    assign o_bram3_sram0_wr_en = bm_wr_en;
    assign o_bram3_sram1_wr_data = bm_wr_data[72 +: 8];
    assign o_bram3_sram1_wr_en = bm_wr_en;
    assign o_bram3_sram2_3_en = 1'b1;
    assign o_bram3_sram2_3_ratio = 2'b00;
    assign o_bram3_sram2_3_rd_addr = bm_rd_addr;
    assign o_bram3_sram2_3_rd_clken = 1'b1;
    assign o_bram3_sram2_3_rd_clkinv = 1'b0;
    assign o_bram3_sram2_3_rd_en = 1'b1;
    assign o_bram3_sram2_3_wr_addr = bm_wr_addr;
    assign o_bram3_sram2_3_wr_clken = 1'b1;
    assign o_bram3_sram2_3_wr_clkinv = 1'b0;
    assign o_bram3_sram2_wr_data = bm_wr_data[80 +: 8];
    assign o_bram3_sram2_wr_en = bm_wr_en;
    assign o_bram3_sram3_wr_data = bm_wr_data[88 +: 8];
    assign o_bram3_sram3_wr_en = bm_wr_en;
endmodule

// ST7735S LCD driver (160x80): pulses the panel reset, plays the init sequence
// from lcd_init_rom, then streams full frames forever.
//
// Content is supplied by the user: o_x / o_y say which pixel is being sent and
// i_color (RGB565) is read back for it. The colour may take up to RD_WAIT clocks
// to settle after o_x / o_y change (e.g. a synchronous BRAM read). There is no
// frame buffer.
//
// One FSM drives everything; the byte engine and the init ROM live in their own
// modules (spi_master, lcd_init_rom).
module lcd_ctrl #(
    parameter       SPI_DIV    = 1,        // SPI clock = clk / (2*SPI_DIV) = 12.5 MHz at 25 MHz
    parameter [3:0] RD_WAIT    = 4'd4,     // clocks between (o_x, o_y) and a valid i_color
    parameter [6:0] IDX_WINDOW = 7'd78,    // ROM index that re-opens the full-screen window
    parameter [1:0] RST_PULSES = 2'd2      // hardware reset pulses at power-up
)(
    input             clk,
    input      [15:0] i_color,             // RGB565 colour of pixel (o_x, o_y)
    output     [7:0]  o_x,                 // 0..159
    output     [6:0]  o_y,                 // 0..79
    output            o_reset,             // active low panel reset
    output            o_cs,
    output            o_dc,
    output            o_mosi,
    output            o_sclk
);
    localparam [7:0] LAST_X = 8'd159;
    localparam [6:0] LAST_Y = 7'd79;

    localparam S_RST_LOW = 4'd0, S_RST_HIGH = 4'd1, S_FETCH = 4'd2, S_W1 = 4'd3,
               S_W2 = 4'd4, S_DLY = 4'd5, S_PREP = 4'd6, S_PIX = 4'd7,
               S_PW1 = 4'd8, S_PW2 = 4'd9, S_RDW = 4'd10, S_PWR = 4'd11;

    // Power-up: RESET stays high for a while (the panel and the oscillator are
    // still settling right after configuration), then RST_PULSES low pulses with
    // recovery time in between. A single pulse right after configuration was not
    // enough on a cold start; a chip reset (everything already stable) worked.
    reg [3:0]  state = S_PWR;
    reg [1:0]  rcnt  = 2'd0;               // reset pulses done
    reg [26:0] t     = 27'd0;              // reset and inter-command delays
    reg [6:0]  idx   = 7'd0;               // init ROM pointer

    reg [7:0]  x = 8'd0;
    reg [6:0]  y = 7'd0;
    reg        lo = 1'b0;                  // 0 = high colour byte, 1 = low byte
    reg [15:0] pix_col = 16'h0000;

    // SPI handshake
    reg       start   = 1'b0;
    reg       tx_dc   = 1'b0;
    reg [7:0] tx_byte = 8'd0;
    wire      busy;

    wire       rom_end, rom_delay, rom_dc;
    wire [7:0] rom_byte;

    assign o_x     = x;
    assign o_y     = y;
    assign o_reset = (state != S_RST_LOW); // low only while in S_RST_LOW

    spi_master #(.DIV(SPI_DIV)) u_spi (
        .clk(clk), .start(start), .tx_dc(tx_dc), .tx_byte(tx_byte),
        .busy(busy), .cs(o_cs), .dc(o_dc), .mosi(o_mosi), .sclk(o_sclk)
    );

    lcd_init_rom u_rom (
        .i_idx(idx), .o_end(rom_end), .o_delay(rom_delay),
        .o_dc(rom_dc), .o_byte(rom_byte)
    );

    always @(posedge clk) begin
        case (state)
            S_PWR: begin                           // RESET high, wait ~168 ms
                t <= t + 27'd1;
                if (t[22]) begin t <= 27'd0; state <= S_RST_LOW; end
            end
            S_RST_LOW: begin                       // hold reset low ~84 ms
                t <= t + 27'd1;
                if (t[21]) begin t <= 27'd0; rcnt <= rcnt + 2'd1; state <= S_RST_HIGH; end
            end
            S_RST_HIGH: begin                      // recovery: ~168 ms between pulses, ~335 ms after the last
                t <= t + 27'd1;
                if (rcnt != RST_PULSES) begin
                    if (t[22]) begin t <= 27'd0; state <= S_RST_LOW; end
                end else if (t[23]) begin
                    t <= 27'd0; state <= S_FETCH;
                end
            end
            S_FETCH: begin
                if (rom_end) begin
                    state <= S_PREP;               // RAMWR sent, start streaming pixels
                end else if (rom_delay) begin
                    t <= 27'd0; state <= S_DLY;
                end else begin
                    tx_dc   <= rom_dc;
                    tx_byte <= rom_byte;
                    start   <= 1'b1;
                    state   <= S_W1;
                end
            end
            S_W1: begin start <= 1'b0; state <= S_W2; end
            S_W2: if (!busy) begin idx <= idx + 7'd1; state <= S_FETCH; end
            S_DLY: begin
                t <= t + 27'd1;
                if (t[23]) begin idx <= idx + 7'd1; state <= S_FETCH; end
            end
            S_PREP: begin                          // let the colour source settle,
                t <= 27'd0;                        // then register the colour and send it
                state <= S_RDW;
            end
            S_RDW: begin
                t <= t + 27'd1;
                if (t[3:0] == RD_WAIT - 4'd1) begin
                    pix_col <= i_color;
                    state   <= S_PIX;
                end
            end
            S_PIX: begin
                tx_dc   <= 1'b1;
                tx_byte <= lo ? pix_col[7:0] : pix_col[15:8];
                start   <= 1'b1;
                state   <= S_PW1;
            end
            S_PW1: begin start <= 1'b0; state <= S_PW2; end
            S_PW2: if (!busy) begin
                if (!lo) begin
                    lo <= 1'b1; state <= S_PIX;    // second byte of the same pixel
                end else begin
                    lo <= 1'b0;
                    if (x != LAST_X) begin
                        x <= x + 8'd1; state <= S_PREP;
                    end else begin
                        x <= 8'd0;
                        if (y != LAST_Y) begin
                            y <= y + 7'd1; state <= S_PREP;
                        end else begin             // frame done: open the window again
                            y <= 7'd0; idx <= IDX_WINDOW; state <= S_FETCH;
                        end
                    end
                end
            end
            default: ;
        endcase
    end
endmodule

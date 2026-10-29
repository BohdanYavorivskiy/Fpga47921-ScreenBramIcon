// 128x64 8-bit colour bitmap stored in the four on-chip BRAMs (RGB332: bits 7:5
// red, 4:2 green, 1:0 blue).
//
// Layout: 4 BRAMs x 4 slices x 512 bytes = 8192 bytes, one byte per pixel
// (0 = black, 255 = white). Pixel (px, py), px 0..127, py 0..63:
//     slice index k = py[5:2]   (BRAM = k[3:2], slice inside the BRAM = k[1:0])
//     address       = {py[1:0], px}
// Every slice is read at the same address, so rd_data of all 16 slices comes in
// as one flat bus and the slice is picked with py[5:2].
//
// The bitmap sits in the middle of the 160x80 screen; the border stays black.
//
// FILL = 0 (used by main) : show the BRAM contents loaded at configuration time.
// FILL = 1 : after power-up the module writes a built-in test picture into all
//            slices (512 clocks), so the display shows something without BRAM
//            initial data. The picture is a left-to-right ramp of the byte value
//            with a white 1-pixel frame.
// FILL = 0 : the BRAM contents loaded at configuration time are shown as they are.
module bram_bitmap #(
    parameter FILL = 1
)(
    input              clk,
    input      [7:0]   i_x,               // screen column 0..159
    input      [6:0]   i_y,               // screen row 0..79
    output     [7:0]   o_pix,             // RGB332 pixel, 0 (black) outside the bitmap window
    output             o_inside,          // pixel lies in the 128x64 bitmap window
    // BRAM side (same bus is connected to every BRAM)
    output     [8:0]   o_wr_addr,
    output             o_wr_en,
    output     [127:0] o_wr_data,         // one byte per slice, slice k = [8*k +: 8]
    output     [8:0]   o_rd_addr,
    input      [127:0] i_rd_data
);
    localparam [7:0] X0 = 8'd16;          // (160 - 128) / 2
    localparam [6:0] Y0 = 7'd8;           // (80 - 64) / 2

    // ---------------- optional power-up fill ----------------
    reg [9:0] fa = 10'd0;                 // write address, bit 9 set = fill finished
    wire      ready = (FILL == 0) || fa[9];
    always @(posedge clk)
        if (FILL != 0 && !fa[9]) fa <= fa + 10'd1;

    assign o_wr_en   = (FILL != 0) && !fa[9];
    assign o_wr_addr = fa[8:0];

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : g_wr
            wire [5:0] wy = {k[3:0], fa[8:7]};    // image row stored at this address
            wire [6:0] wx = fa[6:0];
            wire       frame = (wx == 7'd0) || (wx == 7'd127) || (wy == 6'd0) || (wy == 6'd63);
            assign o_wr_data[8*k +: 8] = frame ? 8'hFF : {wx, wx[6]};
        end
    endgenerate

    // ---------------- read side ----------------
    wire [7:0] dx = i_x - X0;
    wire [6:0] dy = i_y - Y0;
    wire       inside = (i_x >= X0) && (i_x < X0 + 8'd128) && (i_y >= Y0) && (i_y < Y0 + 7'd64);
    wire [6:0] px = dx[6:0];
    wire [5:0] py = dy[5:0];

    assign o_rd_addr = {py[1:0], px};

    wire [3:0] sel = py[5:2];
    wire [7:0] raw = i_rd_data[8*sel +: 8];
    assign o_pix   = (inside && ready) ? raw : 8'h00;
    assign o_inside = inside;
endmodule

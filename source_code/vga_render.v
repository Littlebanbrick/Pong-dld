// ============================================================================
// vga_render.v - VGA image generator with integrated font ROM
//                Supports score digits and "GAME OVER" message
// ============================================================================

`include "defines.vh"

module vga_render (
    input  wire        clk,          // 25.175 MHz pixel clock
    input  wire        rdn,          // active low display enable
    input  wire [8:0]  row_addr,     // current row (0-479)
    input  wire [9:0]  col_addr,     // current column (0-639)
    // Game object coordinates
    input  wire [9:0]  ball_x,       // ball leftmost pixel X
    input  wire [9:0]  ball_y,       // ball topmost pixel Y
    input  wire [9:0]  paddle_left_y,
    input  wire [9:0]  paddle_right_y,
    input  wire [3:0]  score_left,
    input  wire [3:0]  score_right,
    input  wire [2:0]  game_state,   // state encoding (S_OVER = 5)
    output reg  [11:0] rgb_out       // {b[3:0], g[3:0], r[3:0]}
);

    // ------------------------------------------------------------------------
    // State constants (must match game_logic.v)
    // ------------------------------------------------------------------------
    localparam S_OVER = 3'd5;

    // ------------------------------------------------------------------------
    // Color definitions (12-bit: R4, G4, B4)
    // ------------------------------------------------------------------------
    localparam COLOR_BLACK   = 12'h000;
    localparam COLOR_WHITE   = 12'hFFF;
    localparam COLOR_GRAY    = 12'h888;

    // ------------------------------------------------------------------------
    // Coordinate shorthand
    // ------------------------------------------------------------------------
    wire [9:0] row = {1'b0, row_addr};
    wire [9:0] col = col_addr;

    // ========================================================================
    // 1. Score digit display (unchanged from previous version)
    // ========================================================================
    reg [7:0] digit_bitmap [0:15];
    reg [3:0] selected_digit;
    reg [9:0] digit_x_base, digit_y_base;

    always @* begin
        // Default: left tens digit
        if (col >= 200 && col < 216 && row >= 30 && row < 46) begin
            selected_digit = score_left / 10;
            digit_x_base = 200;
            digit_y_base = 30;
        end else if (col >= 216 && col < 232 && row >= 30 && row < 46) begin
            selected_digit = score_left % 10;
            digit_x_base = 216;
            digit_y_base = 30;
        end else if (col >= 408 && col < 424 && row >= 30 && row < 46) begin
            selected_digit = score_right / 10;
            digit_x_base = 408;
            digit_y_base = 30;
        end else if (col >= 424 && col < 440 && row >= 30 && row < 46) begin
            selected_digit = score_right % 10;
            digit_x_base = 424;
            digit_y_base = 30;
        end else begin
            selected_digit = 4'd0;
            digit_x_base = 0;
            digit_y_base = 0;
        end
    end

    // Digit bitmap ROM (0-9) – same as before
    always @* begin
        case (selected_digit)
            4'd0: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b11000110; digit_bitmap[3]  = 8'b11000110;
                digit_bitmap[4]  = 8'b11000110; digit_bitmap[5]  = 8'b11000110;
                digit_bitmap[6]  = 8'b11000110; digit_bitmap[7]  = 8'b11000110;
                digit_bitmap[8]  = 8'b11000110; digit_bitmap[9]  = 8'b11000110;
                digit_bitmap[10] = 8'b11000110; digit_bitmap[11] = 8'b11000110;
                digit_bitmap[12] = 8'b11000110; digit_bitmap[13] = 8'b11000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            4'd1: begin
                digit_bitmap[0]  = 8'b00011000; digit_bitmap[1]  = 8'b00111000;
                digit_bitmap[2]  = 8'b01111000; digit_bitmap[3]  = 8'b00011000;
                digit_bitmap[4]  = 8'b00011000; digit_bitmap[5]  = 8'b00011000;
                digit_bitmap[6]  = 8'b00011000; digit_bitmap[7]  = 8'b00011000;
                digit_bitmap[8]  = 8'b00011000; digit_bitmap[9]  = 8'b00011000;
                digit_bitmap[10] = 8'b00011000; digit_bitmap[11] = 8'b00011000;
                digit_bitmap[12] = 8'b00011000; digit_bitmap[13] = 8'b00011000;
                digit_bitmap[14] = 8'b00011000; digit_bitmap[15] = 8'b01111110;
            end
            4'd2: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b00000110; digit_bitmap[3]  = 8'b00000110;
                digit_bitmap[4]  = 8'b00001100; digit_bitmap[5]  = 8'b00011000;
                digit_bitmap[6]  = 8'b00110000; digit_bitmap[7]  = 8'b01100000;
                digit_bitmap[8]  = 8'b11000000; digit_bitmap[9]  = 8'b11000000;
                digit_bitmap[10] = 8'b11000000; digit_bitmap[11] = 8'b11000000;
                digit_bitmap[12] = 8'b11000000; digit_bitmap[13] = 8'b11000000;
                digit_bitmap[14] = 8'b11000000; digit_bitmap[15] = 8'b11111110;
            end
            4'd3: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b00000110; digit_bitmap[3]  = 8'b00000110;
                digit_bitmap[4]  = 8'b00000110; digit_bitmap[5]  = 8'b00111100;
                digit_bitmap[6]  = 8'b00000110; digit_bitmap[7]  = 8'b00000110;
                digit_bitmap[8]  = 8'b00000110; digit_bitmap[9]  = 8'b00000110;
                digit_bitmap[10] = 8'b00000110; digit_bitmap[11] = 8'b00000110;
                digit_bitmap[12] = 8'b00000110; digit_bitmap[13] = 8'b11000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            4'd4: begin
                digit_bitmap[0]  = 8'b00001100; digit_bitmap[1]  = 8'b00011100;
                digit_bitmap[2]  = 8'b00111100; digit_bitmap[3]  = 8'b01101100;
                digit_bitmap[4]  = 8'b11001100; digit_bitmap[5]  = 8'b11001100;
                digit_bitmap[6]  = 8'b11001100; digit_bitmap[7]  = 8'b11111110;
                digit_bitmap[8]  = 8'b00001100; digit_bitmap[9]  = 8'b00001100;
                digit_bitmap[10] = 8'b00001100; digit_bitmap[11] = 8'b00001100;
                digit_bitmap[12] = 8'b00001100; digit_bitmap[13] = 8'b00001100;
                digit_bitmap[14] = 8'b00001100; digit_bitmap[15] = 8'b00011110;
            end
            4'd5: begin
                digit_bitmap[0]  = 8'b11111110; digit_bitmap[1]  = 8'b11000000;
                digit_bitmap[2]  = 8'b11000000; digit_bitmap[3]  = 8'b11000000;
                digit_bitmap[4]  = 8'b11000000; digit_bitmap[5]  = 8'b11111100;
                digit_bitmap[6]  = 8'b00000110; digit_bitmap[7]  = 8'b00000110;
                digit_bitmap[8]  = 8'b00000110; digit_bitmap[9]  = 8'b00000110;
                digit_bitmap[10] = 8'b00000110; digit_bitmap[11] = 8'b00000110;
                digit_bitmap[12] = 8'b00000110; digit_bitmap[13] = 8'b11000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            4'd6: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b11000000; digit_bitmap[3]  = 8'b11000000;
                digit_bitmap[4]  = 8'b11000000; digit_bitmap[5]  = 8'b11111100;
                digit_bitmap[6]  = 8'b11000110; digit_bitmap[7]  = 8'b11000110;
                digit_bitmap[8]  = 8'b11000110; digit_bitmap[9]  = 8'b11000110;
                digit_bitmap[10] = 8'b11000110; digit_bitmap[11] = 8'b11000110;
                digit_bitmap[12] = 8'b11000110; digit_bitmap[13] = 8'b11000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            4'd7: begin
                digit_bitmap[0]  = 8'b11111110; digit_bitmap[1]  = 8'b00000110;
                digit_bitmap[2]  = 8'b00001100; digit_bitmap[3]  = 8'b00001100;
                digit_bitmap[4]  = 8'b00011000; digit_bitmap[5]  = 8'b00011000;
                digit_bitmap[6]  = 8'b00110000; digit_bitmap[7]  = 8'b00110000;
                digit_bitmap[8]  = 8'b01100000; digit_bitmap[9]  = 8'b01100000;
                digit_bitmap[10] = 8'b01100000; digit_bitmap[11] = 8'b01100000;
                digit_bitmap[12] = 8'b01100000; digit_bitmap[13] = 8'b01100000;
                digit_bitmap[14] = 8'b01100000; digit_bitmap[15] = 8'b01100000;
            end
            4'd8: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b11000110; digit_bitmap[3]  = 8'b11000110;
                digit_bitmap[4]  = 8'b11000110; digit_bitmap[5]  = 8'b01111100;
                digit_bitmap[6]  = 8'b11000110; digit_bitmap[7]  = 8'b11000110;
                digit_bitmap[8]  = 8'b11000110; digit_bitmap[9]  = 8'b11000110;
                digit_bitmap[10] = 8'b11000110; digit_bitmap[11] = 8'b11000110;
                digit_bitmap[12] = 8'b11000110; digit_bitmap[13] = 8'b11000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            4'd9: begin
                digit_bitmap[0]  = 8'b01111100; digit_bitmap[1]  = 8'b11000110;
                digit_bitmap[2]  = 8'b11000110; digit_bitmap[3]  = 8'b11000110;
                digit_bitmap[4]  = 8'b11000110; digit_bitmap[5]  = 8'b11000110;
                digit_bitmap[6]  = 8'b11000110; digit_bitmap[7]  = 8'b11000110;
                digit_bitmap[8]  = 8'b11000110; digit_bitmap[9]  = 8'b11000110;
                digit_bitmap[10] = 8'b11000110; digit_bitmap[11] = 8'b11000110;
                digit_bitmap[12] = 8'b01111110; digit_bitmap[13] = 8'b00000110;
                digit_bitmap[14] = 8'b11000110; digit_bitmap[15] = 8'b01111100;
            end
            default: begin
                digit_bitmap[0]  = 8'b00000000; digit_bitmap[1]  = 8'b00000000;
                digit_bitmap[2]  = 8'b00000000; digit_bitmap[3]  = 8'b00000000;
                digit_bitmap[4]  = 8'b00000000; digit_bitmap[5]  = 8'b00000000;
                digit_bitmap[6]  = 8'b00000000; digit_bitmap[7]  = 8'b00000000;
                digit_bitmap[8]  = 8'b00000000; digit_bitmap[9]  = 8'b00000000;
                digit_bitmap[10] = 8'b00000000; digit_bitmap[11] = 8'b00000000;
                digit_bitmap[12] = 8'b00000000; digit_bitmap[13] = 8'b00000000;
                digit_bitmap[14] = 8'b00000000; digit_bitmap[15] = 8'b00000000;
            end
        endcase
    end

    wire digit_pixel_on;
    wire [3:0] row_in_digit = row[3:0] - digit_y_base[3:0];
    wire [2:0] col_in_digit = col[2:0] - digit_x_base[2:0];
    assign digit_pixel_on = (row >= digit_y_base) && (row < digit_y_base + 16) &&
                            (col >= digit_x_base) && (col < digit_x_base + 8) &&
                            digit_bitmap[row_in_digit][7 - col_in_digit];

    // ========================================================================
    // 2. "GAME OVER" message display
    // ========================================================================
    // Letters needed: G, A, M, E, (space), O, V, E, R
    // We store them in a small ROM, each letter 8 pixels wide, 16 rows tall.
    // Letter index: 0=G, 1=A, 2=M, 3=E, 4=space, 5=O, 6=V, 7=E, 8=R
    // TEXT_SCALE controls pixel doubling (1=8x16 per char, 2=16x32, etc.)
    wire [3:0] letter_index;
    wire [3:0] row_in_char;
    wire [2:0] col_in_char;
    reg [7:0] letter_row;   // 8-bit row data for the selected letter

    // Position of "GAME OVER" on screen (centered, scaled by TEXT_SCALE)
    localparam CHAR_W      = 8  * `TEXT_SCALE;   // scaled char width
    localparam CHAR_H      = 16 * `TEXT_SCALE;   // scaled char height
    localparam GAMEOVER_W  = 9 * CHAR_W;         // 9 chars total width
    localparam GAMEOVER_H  = CHAR_H;
    localparam GAMEOVER_X  = (`SCREEN_W  - GAMEOVER_W) / 2;
    localparam GAMEOVER_Y  = (`SCREEN_H  - GAMEOVER_H) / 2;

    wire inside_gameover;
    assign inside_gameover = (game_state == S_OVER) &&
                             (col >= GAMEOVER_X) && (col < GAMEOVER_X + GAMEOVER_W) &&
                             (row >= GAMEOVER_Y) && (row < GAMEOVER_Y + GAMEOVER_H);

    // Determine which letter we are in (0 .. 8), with pixel scaling
    wire [9:0] local_x = col - GAMEOVER_X;
    wire [9:0] local_y = row - GAMEOVER_Y;

    assign letter_index = local_x / CHAR_W;               // which char
    assign row_in_char  = local_y / `TEXT_SCALE;          // which row in bitmap
    assign col_in_char  = (local_x % CHAR_W) / `TEXT_SCALE; // which col in bitmap

    // Letter bitmap ROM
    always @* begin
        case (letter_index)
            0: // G
                case (row_in_char)
                    4'd0: letter_row = 8'b01111100;
                    4'd1: letter_row = 8'b11000110;
                    4'd2: letter_row = 8'b11000000;
                    4'd3: letter_row = 8'b11000000;
                    4'd4: letter_row = 8'b11000000;
                    4'd5: letter_row = 8'b11001110;
                    4'd6: letter_row = 8'b11000110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b11000110;
                    4'd13: letter_row = 8'b11000110;
                    4'd14: letter_row = 8'b11000110;
                    4'd15: letter_row = 8'b01111100;
                endcase
            1: // A
                case (row_in_char)
                    4'd0: letter_row = 8'b00010000;
                    4'd1: letter_row = 8'b00111000;
                    4'd2: letter_row = 8'b01101100;
                    4'd3: letter_row = 8'b11000110;
                    4'd4: letter_row = 8'b11000110;
                    4'd5: letter_row = 8'b11000110;
                    4'd6: letter_row = 8'b11111110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b11000110;
                    4'd13: letter_row = 8'b11000110;
                    4'd14: letter_row = 8'b11000110;
                    4'd15: letter_row = 8'b11000110;
                endcase
            2: // M
                case (row_in_char)
                    4'd0: letter_row = 8'b10000010;
                    4'd1: letter_row = 8'b11000110;
                    4'd2: letter_row = 8'b11101110;
                    4'd3: letter_row = 8'b11111110;
                    4'd4: letter_row = 8'b11010110;
                    4'd5: letter_row = 8'b11000110;
                    4'd6: letter_row = 8'b11000110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b11000110;
                    4'd13: letter_row = 8'b11000110;
                    4'd14: letter_row = 8'b11000110;
                    4'd15: letter_row = 8'b11000110;
                endcase
            3: // E
                case (row_in_char)
                    4'd0: letter_row = 8'b11111110;
                    4'd1: letter_row = 8'b11000000;
                    4'd2: letter_row = 8'b11000000;
                    4'd3: letter_row = 8'b11000000;
                    4'd4: letter_row = 8'b11000000;
                    4'd5: letter_row = 8'b11111100;
                    4'd6: letter_row = 8'b11000000;
                    4'd7: letter_row = 8'b11000000;
                    4'd8: letter_row = 8'b11000000;
                    4'd9: letter_row = 8'b11000000;
                    4'd10: letter_row = 8'b11000000;
                    4'd11: letter_row = 8'b11000000;
                    4'd12: letter_row = 8'b11000000;
                    4'd13: letter_row = 8'b11000000;
                    4'd14: letter_row = 8'b11000000;
                    4'd15: letter_row = 8'b11111110;
                endcase
            4: // space
                letter_row = 8'b00000000;
            5: // O
                case (row_in_char)
                    4'd0: letter_row = 8'b01111100;
                    4'd1: letter_row = 8'b11000110;
                    4'd2: letter_row = 8'b11000110;
                    4'd3: letter_row = 8'b11000110;
                    4'd4: letter_row = 8'b11000110;
                    4'd5: letter_row = 8'b11000110;
                    4'd6: letter_row = 8'b11000110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b11000110;
                    4'd13: letter_row = 8'b11000110;
                    4'd14: letter_row = 8'b11000110;
                    4'd15: letter_row = 8'b01111100;
                endcase
            6: // V
                case (row_in_char)
                    4'd0: letter_row = 8'b11000110;
                    4'd1: letter_row = 8'b11000110;
                    4'd2: letter_row = 8'b11000110;
                    4'd3: letter_row = 8'b11000110;
                    4'd4: letter_row = 8'b11000110;
                    4'd5: letter_row = 8'b11000110;
                    4'd6: letter_row = 8'b11000110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b01101100;
                    4'd13: letter_row = 8'b00111000;
                    4'd14: letter_row = 8'b00010000;
                    4'd15: letter_row = 8'b00000000;
                endcase
            7: // E (same as index 3)
                case (row_in_char)
                    4'd0: letter_row = 8'b11111110;
                    4'd1: letter_row = 8'b11000000;
                    4'd2: letter_row = 8'b11000000;
                    4'd3: letter_row = 8'b11000000;
                    4'd4: letter_row = 8'b11000000;
                    4'd5: letter_row = 8'b11111100;
                    4'd6: letter_row = 8'b11000000;
                    4'd7: letter_row = 8'b11000000;
                    4'd8: letter_row = 8'b11000000;
                    4'd9: letter_row = 8'b11000000;
                    4'd10: letter_row = 8'b11000000;
                    4'd11: letter_row = 8'b11000000;
                    4'd12: letter_row = 8'b11000000;
                    4'd13: letter_row = 8'b11000000;
                    4'd14: letter_row = 8'b11000000;
                    4'd15: letter_row = 8'b11111110;
                endcase
            8: // R
                case (row_in_char)
                    4'd0: letter_row = 8'b11111100;
                    4'd1: letter_row = 8'b11000110;
                    4'd2: letter_row = 8'b11000110;
                    4'd3: letter_row = 8'b11000110;
                    4'd4: letter_row = 8'b11000110;
                    4'd5: letter_row = 8'b11111100;
                    4'd6: letter_row = 8'b11000110;
                    4'd7: letter_row = 8'b11000110;
                    4'd8: letter_row = 8'b11000110;
                    4'd9: letter_row = 8'b11000110;
                    4'd10: letter_row = 8'b11000110;
                    4'd11: letter_row = 8'b11000110;
                    4'd12: letter_row = 8'b11000110;
                    4'd13: letter_row = 8'b11000110;
                    4'd14: letter_row = 8'b11000110;
                    4'd15: letter_row = 8'b11000110;
                endcase
            default: letter_row = 8'b00000000;
        endcase
    end

    wire gameover_pixel_on;
    assign gameover_pixel_on = inside_gameover &&
                               letter_row[7 - col_in_char];  // MSB = leftmost pixel

    // ========================================================================
    // 3. Final pixel output (priority: GAME OVER > ball/paddles/score/line)
    // ========================================================================
    always @* begin
        if (!rdn) begin
            // Default background
            rgb_out = COLOR_BLACK;

            // Center dashed line (only if not game over, or behind text? we keep it)
            if (col >= 318 && col <= 320 && (row[3:0] < 8))
                rgb_out = COLOR_WHITE;

            // Ball
            if (col >= ball_x && col < ball_x + `BALL_SIZE &&
                row >= ball_y && row < ball_y + `BALL_SIZE)
                rgb_out = COLOR_WHITE;

            // Left paddle
            if (col >= `LEFT_PADDLE_X && col < `LEFT_PADDLE_X + `PADDLE_W &&
                row >= paddle_left_y && row < paddle_left_y + `PADDLE_H)
                rgb_out = COLOR_WHITE;

            // Right paddle
            if (col >= `RIGHT_PADDLE_X && col < `RIGHT_PADDLE_X + `PADDLE_W &&
                row >= paddle_right_y && row < paddle_right_y + `PADDLE_H)
                rgb_out = COLOR_WHITE;

            // Score digits
            if (digit_pixel_on)
                rgb_out = COLOR_WHITE;

            // Game Over message (highest priority, covers everything behind)
            if (gameover_pixel_on)
                rgb_out = COLOR_WHITE;

        end else begin
            rgb_out = COLOR_BLACK;   // blanking period
        end
    end

endmodule
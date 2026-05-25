// ============================================================================
// seg_display.v - 4-digit 7-segment display driver (common anode)
// Displays score_left (2 digits) and score_right (2 digits)
// ============================================================================

`include "defines.vh"

module seg_display (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  score_left,
    input  wire [3:0]  score_right,
    output reg  [3:0]  AN,
    output reg  [7:0]  SEGMENT
);

    // ------------------------------------------------------------------------
    // Digit decoding (active low for common anode)
    // SEGMENT mapping: {dp, g, f, e, d, c, b, a}
    // ------------------------------------------------------------------------
    localparam SEG_0 = 8'b11000000;
    localparam SEG_1 = 8'b11111001;
    localparam SEG_2 = 8'b10100100;
    localparam SEG_3 = 8'b10110000;
    localparam SEG_4 = 8'b10011001;
    localparam SEG_5 = 8'b10010010;
    localparam SEG_6 = 8'b10000010;
    localparam SEG_7 = 8'b11111000;
    localparam SEG_8 = 8'b10000000;
    localparam SEG_9 = 8'b10010000;
    localparam SEG_OFF = 8'b11111111;

    function [7:0] digit_to_seg;
        input [3:0] digit;
        case (digit)
            4'd0: digit_to_seg = SEG_0;
            4'd1: digit_to_seg = SEG_1;
            4'd2: digit_to_seg = SEG_2;
            4'd3: digit_to_seg = SEG_3;
            4'd4: digit_to_seg = SEG_4;
            4'd5: digit_to_seg = SEG_5;
            4'd6: digit_to_seg = SEG_6;
            4'd7: digit_to_seg = SEG_7;
            4'd8: digit_to_seg = SEG_8;
            4'd9: digit_to_seg = SEG_9;
            default: digit_to_seg = SEG_OFF;
        endcase
    endfunction

    // ------------------------------------------------------------------------
    // Scan timing (4 kHz refresh)
    // ------------------------------------------------------------------------
    reg [12:0] scan_counter;
    wire scan_tick;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scan_counter <= 13'd0;
        else if (scan_counter == `SCAN_MAX)
            scan_counter <= 13'd0;
        else
            scan_counter <= scan_counter + 1;
    end
    assign scan_tick = (scan_counter == `SCAN_MAX);

    // ------------------------------------------------------------------------
    // Digit multiplexing
    // ------------------------------------------------------------------------
    reg [1:0] digit_sel;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_sel <= 2'd0;
            AN        <= 4'b1111;
            SEGMENT   <= 8'hFF;
        end else if (scan_tick) begin
            digit_sel <= digit_sel + 1;
            case (digit_sel)
                2'd0: begin  // Left tens
                    AN <= 4'b1110;
                    SEGMENT <= digit_to_seg(score_left / 10);
                end
                2'd1: begin  // Left ones
                    AN <= 4'b1101;
                    SEGMENT <= digit_to_seg(score_left % 10);
                end
                2'd2: begin  // Right tens
                    AN <= 4'b1011;
                    SEGMENT <= digit_to_seg(score_right / 10);
                end
                2'd3: begin  // Right ones
                    AN <= 4'b0111;
                    SEGMENT <= digit_to_seg(score_right % 10);
                end
            endcase
        end
    end

endmodule
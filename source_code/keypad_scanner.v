// ============================================================================
// keypad_scanner.v - 5x4 matrix keyboard scanner with debounce
// Outputs: left_up, left_down, right_up, right_down, start_pause
//
// Physical key mapping (revised):
//   Row 4 (paddle controls):
//     Col 0 -> left_down
//     Col 1 -> left_up
//     Col 2 -> right_down
//     Col 3 -> right_up
//   Row 0:
//     Col 0 -> start_pause
// ============================================================================

`include "defines.vh"

module keypad_scanner (
    input  wire        clk,          // 25.175 MHz
    input  wire        rst_n,
    output reg  [4:0]  key_row,      // driven low one at a time
    input  wire [3:0]  key_col,      // read with internal pull-up
    output reg         left_up,
    output reg         left_down,
    output reg         right_up,
    output reg         right_down,
    output reg         start_pause
);

    // ------------------------------------------------------------------------
    // Row identifiers
    // ------------------------------------------------------------------------
    localparam ROW_PADDLE = 3'd4;  // paddle controls (4 keys)
    localparam ROW_START  = 3'd0;  // start/pause

    // ------------------------------------------------------------------------
    // Scan timing: scan each row for ~1 ms -> 5 kHz total scan rate
    // 25.175 MHz / 5000 = 5035 -> use 5035
    // ------------------------------------------------------------------------
    localparam SCAN_DELAY = 5035;    // simulation: 10
    // localparam SCAN_DELAY = 10;

    reg [12:0] scan_cnt;
    wire scan_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scan_cnt <= 13'd0;
        else if (scan_cnt == SCAN_DELAY - 1)
            scan_cnt <= 13'd0;
        else
            scan_cnt <= scan_cnt + 1;
    end
    assign scan_tick = (scan_cnt == SCAN_DELAY - 1);

    // ------------------------------------------------------------------------
    // Row driver state machine
    // ------------------------------------------------------------------------
    reg [2:0] current_row;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_row <= 3'd0;
            key_row <= 5'b11111;      // all rows inactive (high)
        end else if (scan_tick) begin
            // Move to next row
            current_row <= (current_row == 3'd4) ? 3'd0 : current_row + 1;

            // Drive exactly one row low
            case (current_row)
                3'd0: key_row <= 5'b11110;
                3'd1: key_row <= 5'b11101;
                3'd2: key_row <= 5'b11011;
                3'd3: key_row <= 5'b10111;
                3'd4: key_row <= 5'b01111;
                default: key_row <= 5'b11111;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // The row that was actually driven during the last scan interval.
    // ------------------------------------------------------------------------
    wire [2:0] prev_row = (current_row == 3'd0) ? 3'd4 : current_row - 3'd1;

    // ------------------------------------------------------------------------
    // Debounce: 8 consecutive stable readings (~8 ms) required
    // ------------------------------------------------------------------------
    localparam DEBOUNCE_CNT = 8;     // number of matching scans

    // Synchronous column capture
    reg [3:0] col_sync;
    always @(posedge clk) begin
        col_sync <= key_col;         // input already synchronized by IOB flops
    end

    // Debounce counters for each key
    reg [3:0] db_cnt_left_up,    db_cnt_left_down;
    reg [3:0] db_cnt_right_up,   db_cnt_right_down;
    reg [3:0] db_cnt_start;

    // Debounced key states
    reg kp_left_up, kp_left_down, kp_right_up, kp_right_down, kp_start;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            db_cnt_left_up   <= 4'd0;
            db_cnt_left_down <= 4'd0;
            db_cnt_right_up  <= 4'd0;
            db_cnt_right_down<= 4'd0;
            db_cnt_start     <= 4'd0;
            kp_left_up       <= 1'b0;
            kp_left_down     <= 1'b0;
            kp_right_up      <= 1'b0;
            kp_right_down    <= 1'b0;
            kp_start         <= 1'b0;
        end else if (scan_tick) begin
            // ========== Paddle controls on Row 4 ==========
            if (prev_row == ROW_PADDLE) begin
                // Col 0 -> left_down
                if (col_sync[0] == 1'b0) begin
                    if (db_cnt_left_down < DEBOUNCE_CNT)
                        db_cnt_left_down <= db_cnt_left_down + 1;
                end else begin
                    if (db_cnt_left_down > 0)
                        db_cnt_left_down <= db_cnt_left_down - 1;
                end
                // Col 1 -> left_up
                if (col_sync[1] == 1'b0) begin
                    if (db_cnt_left_up < DEBOUNCE_CNT)
                        db_cnt_left_up <= db_cnt_left_up + 1;
                end else begin
                    if (db_cnt_left_up > 0)
                        db_cnt_left_up <= db_cnt_left_up - 1;
                end
                // Col 2 -> right_down
                if (col_sync[2] == 1'b0) begin
                    if (db_cnt_right_down < DEBOUNCE_CNT)
                        db_cnt_right_down <= db_cnt_right_down + 1;
                end else begin
                    if (db_cnt_right_down > 0)
                        db_cnt_right_down <= db_cnt_right_down - 1;
                end
                // Col 3 -> right_up
                if (col_sync[3] == 1'b0) begin
                    if (db_cnt_right_up < DEBOUNCE_CNT)
                        db_cnt_right_up <= db_cnt_right_up + 1;
                end else begin
                    if (db_cnt_right_up > 0)
                        db_cnt_right_up <= db_cnt_right_up - 1;
                end

                // Update debounced outputs
                kp_left_down <= (db_cnt_left_down == DEBOUNCE_CNT) ||
                                ((db_cnt_left_down == DEBOUNCE_CNT-1) && (col_sync[0] == 1'b0));
                kp_left_up   <= (db_cnt_left_up   == DEBOUNCE_CNT) ||
                                ((db_cnt_left_up   == DEBOUNCE_CNT-1) && (col_sync[1] == 1'b0));
                kp_right_down<= (db_cnt_right_down == DEBOUNCE_CNT) ||
                                ((db_cnt_right_down == DEBOUNCE_CNT-1) && (col_sync[2] == 1'b0));
                kp_right_up  <= (db_cnt_right_up  == DEBOUNCE_CNT) ||
                                ((db_cnt_right_up  == DEBOUNCE_CNT-1) && (col_sync[3] == 1'b0));
            end

            // ========== Start/Pause on Row 0 ==========
            if (prev_row == ROW_START) begin
                if (col_sync[0] == 1'b0) begin
                    if (db_cnt_start < DEBOUNCE_CNT)
                        db_cnt_start <= db_cnt_start + 1;
                end else begin
                    if (db_cnt_start > 0)
                        db_cnt_start <= db_cnt_start - 1;
                end

                kp_start <= (db_cnt_start == DEBOUNCE_CNT) ||
                            ((db_cnt_start == DEBOUNCE_CNT-1) && (col_sync[0] == 1'b0));
            end
        end
    end

    // ------------------------------------------------------------------------
    // Output assignment
    // ------------------------------------------------------------------------
    always @* begin
        left_up     = kp_left_up;
        left_down   = kp_left_down;
        right_up    = kp_right_up;
        right_down  = kp_right_down;
        start_pause = kp_start;
    end

endmodule

// ============================================================================
// ai_paddle.v - Simple AI opponent for Pong
// Tracks the ball's Y coordinate with a dead zone, limited speed,
// and randomized update delay to reduce AI strength.
// When the ball is moving away, drifts toward screen center.
// ============================================================================

`include "defines.vh"

module ai_paddle (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        game_tick,
    input  wire [9:0]  ball_y,
    input  wire [9:0]  paddle_y,
    input  wire        ball_toward_ai,   // 1 = ball moving toward this paddle
    output reg         move_up,
    output reg         move_down
);

    // Center-of-gravity calculations
    wire [9:0] ball_center_y   = ball_y   + (`BALL_SIZE / 2);
    wire [9:0] paddle_center_y = paddle_y + (`PADDLE_H  / 2);

    // Clamped comparison bounds for tracking, preventing unsigned underflow
    // when paddle is near the screen edge and DEAD_ZONE is large.
    wire [9:0] track_lower = (paddle_center_y > `AI_DEAD_ZONE)
                           ? (paddle_center_y - `AI_DEAD_ZONE) : 10'd0;
    wire [9:0] track_upper = paddle_center_y + `AI_DEAD_ZONE;   // can't overflow (max ~520 < 1024)

    // ------------------------------------------------------------------------
    // Randomized update delay
    // AI only samples ball position every (AI_UPDATE_BASE + rand) game ticks.
    // Between updates, move_up/move_down hold their last decision.
    // ------------------------------------------------------------------------
    reg [15:0] rand_cnt;       // free-running counter for pseudo-random delay
    reg [5:0]  update_timer;   // counts down each game_tick; update when 0
    reg [7:0]  osc_phase;      // phase counter for idle oscillation
    reg        osc_dir;         // 0 = oscillate up, 1 = oscillate down

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rand_cnt     <= 16'd0;
            update_timer <= 6'd0;
            osc_phase    <= 8'd0;
            osc_dir      <= 1'b0;
            move_up      <= 1'b0;
            move_down    <= 1'b0;
        end else if (game_tick) begin
            rand_cnt <= rand_cnt + 1;

            // Idle oscillation: free-running phase counter
            // Flipping direction every ~32 game ticks gives ~64 pixel amplitude
            // (PADDLE_SPEED = 2, so each half-cycle travels 2 * 32 = 64 pixels)
            osc_phase <= osc_phase + 1;
            if (&osc_phase[4:0])        // every 32 game ticks
                osc_dir <= ~osc_dir;

            if (update_timer == 6'd0) begin
                if (ball_toward_ai) begin
                    // Ball coming toward us: track it with dead zone
                    if (ball_center_y < track_lower) begin
                        move_up   <= 1'b1;
                        move_down <= 1'b0;
                    end else if (ball_center_y > track_upper) begin
                        move_up   <= 1'b0;
                        move_down <= 1'b1;
                    end else begin
                        // Within dead zone — oscillate to avoid standing still
                        move_up   <= ~osc_dir;
                        move_down <=  osc_dir;
                    end
                end else begin
                    // Ball moving away: drift back toward screen center
                    if (paddle_center_y > 10'd240 + `AI_DEAD_ZONE) begin
                        // Paddle below center -> move UP to return
                        move_up   <= 1'b1;
                        move_down <= 1'b0;
                    end else if (paddle_center_y < 10'd240 - `AI_DEAD_ZONE) begin
                        // Paddle above center -> move DOWN to return
                        move_up   <= 1'b0;
                        move_down <= 1'b1;
                    end else begin
                        // Paddle near center, ball moving away — oscillate
                        move_up   <= ~osc_dir;
                        move_down <=  osc_dir;
                    end
                end

                // Reload timer with base + pseudo-random offset (0 ~ AI_UPDATE_RANGE-1)
                update_timer <= `AI_UPDATE_BASE + rand_cnt[3:0];
            end else begin
                // Count down each game tick
                update_timer <= update_timer - 1;
            end
        end
    end

endmodule

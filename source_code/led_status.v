// ============================================================================
// led_status.v - LED status indicator for Pong
// 8 LEDs arranged as follows:
//   [7]: Game Over (solid)
//   [6]: Pause (blinking)
//   [5]: Score event (quick blink)
//   [4]: Hit paddle (quick blink)
//   [3]: Serving side (1 = right, 0 = left)
//   [2]: Playing (solid when in PLAY state)
//   [1]: Serve (solid when in SERVE state)
//   [0]: Idle (solid when in IDLE state)
// ============================================================================

`include "defines.vh"

module led_status (
    input  wire        clk,          // 25.175 MHz
    input  wire        rst_n,
    input  wire [2:0]  game_state,
    input  wire [3:0]  score_left,
    input  wire [3:0]  score_right,
    input  wire        serve_side,   // 0 = left, 1 = right
    output reg  [7:0]  led
);

    // State encoding (must match game_logic.v)
    localparam S_IDLE  = 3'd0;
    localparam S_SERVE = 3'd1;
    localparam S_PLAY  = 3'd2;
    localparam S_PAUSE = 3'd3;
    localparam S_SCORE = 3'd4;
    localparam S_OVER  = 3'd5;

    // ------------------------------------------------------------------------
    // Blink timer: for Pause and other blinking patterns
    // 25.175 MHz / 12.5M -> 0.5 Hz blink (1 sec period)
    // Simulation: use small value to see blink
    // ------------------------------------------------------------------------
    localparam BLINK_MAX = 24'd12_500_000;  // simulation: 10
    reg [23:0] blink_cnt;
    wire blink_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            blink_cnt <= 24'd0;
        else if (blink_cnt == BLINK_MAX - 1)
            blink_cnt <= 24'd0;
        else
            blink_cnt <= blink_cnt + 1;
    end
    assign blink_tick = (blink_cnt == BLINK_MAX - 1);

    // Blink phase toggles every blink_tick
    reg blink_phase;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            blink_phase <= 1'b0;
        else if (blink_tick)
            blink_phase <= ~blink_phase;
    end

    // ------------------------------------------------------------------------
    // LED output logic (active high)
    // ------------------------------------------------------------------------
    always @* begin
        led = 8'b00000000;

        case (game_state)
            S_IDLE: begin
                led[0] = 1'b1;     // Idle LED
            end
            S_SERVE: begin
                led[1] = 1'b1;     // Serve LED
                led[3] = serve_side; // show who serves
            end
            S_PLAY: begin
                led[2] = 1'b1;     // Playing LED
                led[3] = serve_side;
            end
            S_PAUSE: begin
                led[6] = blink_phase;  // Pause LED blinking
                led[3] = serve_side;
            end
            S_SCORE: begin
                led[5] = blink_phase;  // Score event blinking
                led[3] = serve_side;
            end
            S_OVER: begin
                led[7] = 1'b1;         // Game Over solid
            end
        endcase
    end

endmodule
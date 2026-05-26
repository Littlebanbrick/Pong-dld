// ============================================================================
// buzzer_ctrl.v - Passive buzzer driver for Pong sound effects
// ============================================================================

`include "defines.vh"

module buzzer_ctrl (
    input  wire  clk,              // 25.175 MHz
    input  wire  rst_n,
    input  wire  hit_paddle,       // pulse when ball hits paddle
    input  wire  score_event,      // pulse when someone scores
    input  wire  game_over_event,  // pulse when game ends
    output reg   buzzer            // square wave output
);

    // ------------------------------------------------------------------------
    // Note frequencies (in Hz) and corresponding half-period counts
    // Half-period = (25.175e6 / frequency) / 2
    // For simulation, we use much smaller values; actual values are commented.
    // ------------------------------------------------------------------------
    // Actual values (comment out for simulation):
    localparam HIT_HALF    = 12587; // 25.175e6 / 1000 / 2 ≈ 12587
    localparam SCORE_HALF  = 8391;  // 25.175e6 / 1500 / 2 ≈ 8391
    localparam OVER_HALF   = 6293;  // 25.175e6 / 2000 / 2 ≈ 6293
    localparam TIMER_MAX   = 5035000; // 0.2 sec * 25.175e6 ≈ 5035000

    // Simulation-friendly values (to see waveform changes quickly)
    // localparam HIT_HALF    = 5;    // divides clk by ~10 -> high freq for fast sim
    // localparam SCORE_HALF  = 8;
    // localparam OVER_HALF   = 12;
    //localparam TIMER_MAX   = 200;  // simulation timer length

    // ------------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------------
    reg [22:0] timer;            // sound duration counter
    reg        sound_active;
    reg [13:0] half_period_cnt;  // counter for half period of current note
    reg        note_phase;       // toggles to generate square wave
    reg [13:0] current_half;     // selected half-period value

    // ------------------------------------------------------------------------
    // Edge detection for event inputs
    // (game_logic outputs are ~16ms pulses; convert to single-cycle)
    // ------------------------------------------------------------------------
    reg hit_paddle_d1;
    reg score_event_d1;
    reg game_over_event_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_paddle_d1    <= 1'b0;
            score_event_d1   <= 1'b0;
            game_over_event_d1 <= 1'b0;
        end else begin
            hit_paddle_d1    <= hit_paddle;
            score_event_d1   <= score_event;
            game_over_event_d1 <= game_over_event;
        end
    end

    wire hit_paddle_rise    = hit_paddle    && !hit_paddle_d1;
    wire score_event_rise   = score_event   && !score_event_d1;
    wire game_over_event_rise = game_over_event && !game_over_event_d1;

    wire any_event = hit_paddle_rise || score_event_rise || game_over_event_rise;

    // ------------------------------------------------------------------------
    // Event detection and timer control
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sound_active <= 1'b0;
            timer <= 23'd0;
            current_half <= HIT_HALF;
        end else begin
            // Check for any new event pulse (edge-detected, always single-cycle)
            if (hit_paddle_rise || score_event_rise || game_over_event_rise) begin
                // Start / restart sound
                sound_active <= 1'b1;
                timer <= 23'd0;

                // Select note based on event (priority: game_over > score > hit)
                if (game_over_event_rise)
                    current_half <= OVER_HALF;
                else if (score_event_rise)
                    current_half <= SCORE_HALF;
                else
                    current_half <= HIT_HALF;
            end else if (sound_active) begin
                if (timer == TIMER_MAX - 1) begin
                    // Duration finished
                    sound_active <= 1'b0;
                end else begin
                    timer <= timer + 1;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Tone generator (toggle when counter reaches half-period)
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            half_period_cnt <= 14'd0;
            note_phase <= 1'b0;
        end else if (sound_active) begin
            // On event, reset half-period counter to avoid
            // stale count > new threshold (which would cause wrap-around)
            if (any_event) begin
                half_period_cnt <= 14'd0;
                note_phase <= 1'b0;
            end else if (half_period_cnt == current_half - 1) begin
                half_period_cnt <= 14'd0;
                note_phase <= ~note_phase;
            end else begin
                half_period_cnt <= half_period_cnt + 1;
            end
        end else begin
            // Not active, keep buzzer low
            half_period_cnt <= 14'd0;
            note_phase <= 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Output assignment
    // ------------------------------------------------------------------------
    always @* begin
        if (sound_active)
            buzzer = note_phase;
        else
            buzzer = 1'b0;
    end

endmodule

// ============================================================================
// input_merger.v - Merge matrix keyboard and PS/2 keyboard signals
// ============================================================================

module input_merger (
    // Matrix keyboard inputs
    input  wire  kp_left_up,
    input  wire  kp_left_down,
    input  wire  kp_right_up,
    input  wire  kp_right_down,
    input  wire  kp_start,
    // PS/2 keyboard inputs
    input  wire  ps2_left_up,
    input  wire  ps2_left_down,
    input  wire  ps2_right_up,
    input  wire  ps2_right_down,
    input  wire  ps2_start,
    input  wire  ps2_soft_reset,
    // Merged outputs (active high)
    output wire  left_up,
    output wire  left_down,
    output wire  right_up,
    output wire  right_down,
    output wire  start_pause,
    output wire  soft_reset
);

    assign left_up     = kp_left_up     | ps2_left_up;
    assign left_down   = kp_left_down   | ps2_left_down;
    assign right_up    = kp_right_up    | ps2_right_up;
    assign right_down  = kp_right_down  | ps2_right_down;
    assign start_pause = kp_start       | ps2_start;
    assign soft_reset  =                 ps2_soft_reset;

endmodule

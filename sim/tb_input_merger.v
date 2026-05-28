// ============================================================================
// tb_input_merger.v - Testbench for input_merger
// ============================================================================
`timescale 1ns / 1ps

module tb_input_merger;

    reg  kp_left_up, kp_left_down, kp_right_up, kp_right_down, kp_start;
    reg  ps2_left_up, ps2_left_down, ps2_right_up, ps2_right_down, ps2_start;
    wire left_up, left_down, right_up, right_down, start_pause;

    input_merger DUT (
        .kp_left_up     (kp_left_up),
        .kp_left_down   (kp_left_down),
        .kp_right_up    (kp_right_up),
        .kp_right_down  (kp_right_down),
        .kp_start       (kp_start),
        .ps2_left_up    (ps2_left_up),
        .ps2_left_down  (ps2_left_down),
        .ps2_right_up   (ps2_right_up),
        .ps2_right_down (ps2_right_down),
        .ps2_start      (ps2_start),
        .left_up        (left_up),
        .left_down      (left_down),
        .right_up       (right_up),
        .right_down     (right_down),
        .start_pause    (start_pause)
    );

    initial begin
        kp_left_up = 0; kp_left_down = 0; kp_right_up = 0; kp_right_down = 0; kp_start = 0;
        ps2_left_up = 0; ps2_left_down = 0; ps2_right_up = 0; ps2_right_down = 0; ps2_start = 0;
        #100;

        // Test kp_left_up alone
        kp_left_up = 1; #20;
        if (left_up !== 1) $display("FAIL: left_up not 1");
        kp_left_up = 0; #20;

        // Test ps2_left_up alone
        ps2_left_up = 1; #20;
        if (left_up !== 1) $display("FAIL: left_up not 1 from ps2");
        ps2_left_up = 0; #20;

        // Test both at same time
        kp_left_up = 1; ps2_left_up = 1; #20;
        if (left_up !== 1) $display("FAIL: left_up not 1 when both high");
        kp_left_up = 0; ps2_left_up = 0; #20;

        // Test start_pause
        kp_start = 1; #20;
        if (start_pause !== 1) $display("FAIL: start_pause not 1");
        kp_start = 0; #20;

        ps2_start = 1; #20;
        if (start_pause !== 1) $display("FAIL: start_pause not 1 from ps2");
        ps2_start = 0; #20;

        // All signals off
        #100;
        if (left_up || left_down || right_up || right_down || start_pause)
            $display("FAIL: some outputs still high");

        $stop;
    end

endmodule
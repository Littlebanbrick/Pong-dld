// ============================================================================
// tb_led_status.v - Testbench for led_status module
// ============================================================================
`timescale 1ns / 1ps

module tb_led_status;

    reg        clk;
    reg        rst_n;
    reg [2:0]  game_state;
    reg [3:0]  score_left, score_right;
    reg        serve_side;
    wire [7:0] led;

    led_status DUT (
        .clk         (clk),
        .rst_n       (rst_n),
        .game_state  (game_state),
        .score_left  (score_left),
        .score_right (score_right),
        .serve_side  (serve_side),
        .led         (led)
    );

    // 25.175 MHz clock
    always #19.86 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        game_state = 0;
        score_left = 0;
        score_right = 0;
        serve_side = 0;

        #200 rst_n = 1;

        // Test IDLE -> led[0] high
        #1000;
        if (led[0] !== 1) $display("FAIL: Idle LED not on");

        // Test SERVE with left serve
        game_state = 1; serve_side = 0;
        #1000;
        if (led[1] !== 1 || led[3] !== 0) $display("FAIL: Serve left LED wrong");

        // Test SERVE with right serve
        serve_side = 1;
        #1000;
        if (led[3] !== 1) $display("FAIL: Serve right LED not showing");

        // Test PLAY
        game_state = 2;
        #1000;
        if (led[2] !== 1) $display("FAIL: Play LED not on");

        // Test PAUSE (blink, need to run simulation long enough to see phase change)
        game_state = 3;
        #100000;  // wait for several blink ticks (simulation BLINK_MAX small)
        // Observe led[6] toggling, just check it's not stuck 0

        // Test SCORE
        game_state = 4;
        #100000;
        // led[5] should toggle

        // Test OVER
        game_state = 5;
        #1000;
        if (led[7] !== 1) $display("FAIL: Game Over LED not on");

        #2000 $stop;
    end

endmodule
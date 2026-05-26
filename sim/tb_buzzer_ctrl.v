// ============================================================================
// tb_buzzer_ctrl.v - Testbench for buzzer_ctrl module
// ============================================================================
`timescale 1ns / 1ps

module tb_buzzer_ctrl;

    reg        clk;
    reg        rst_n;
    reg        hit_paddle;
    reg        score_event;
    reg        game_over_event;
    wire       buzzer;

    buzzer_ctrl DUT (
        .clk             (clk),
        .rst_n           (rst_n),
        .hit_paddle      (hit_paddle),
        .score_event     (score_event),
        .game_over_event (game_over_event),
        .buzzer          (buzzer)
    );

    // 25.175 MHz clock (period ~39.7 ns)
    always #19.86 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        hit_paddle      = 0;
        score_event     = 0;
        game_over_event = 0;

        #100 rst_n = 1;

        // Test 1: hit paddle event
        #200;
        hit_paddle = 1;
        #40;              // pulse width > one clock period
        hit_paddle = 0;
        // Wait to observe sound output
        #5000;

        // Test 2: score event (should override and restart)
        score_event = 1;
        #40;
        score_event = 0;
        #5000;

        // Test 3: game over event
        game_over_event = 1;
        #40;
        game_over_event = 0;
        #10000;           // wait until timer expires

        // Test 4: multiple events in quick succession
        hit_paddle = 1;
        #40; hit_paddle = 0;
        #100;
        score_event = 1;
        #40; score_event = 0;
        #100;
        game_over_event = 1;
        #40; game_over_event = 0;
        #5000;

        $stop;
    end

endmodule
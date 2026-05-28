// ============================================================================
// clk_wiz_0_sim.v — Simulation replacement for Xilinx clk_wiz_0 IP
// ============================================================================
// This module replaces the clk_wiz_0 MMCM IP during simulation.  It generates
// a 25 MHz clock from the 100 MHz input and asserts LOCKED after a short
// warm-up period.  No force/release statements are needed in the testbench.
//
// USAGE: Add this file to Vivado simulation sources.  Ensure it appears
//        BEFORE clk_wiz_0 in the compile order so it shadows the IP.
//        In Vivado: right-click sim sources → Add Sources → this file.
//        Then in Simulation Settings → Elaboration → set this file's
//        compile order to be higher priority than the IP.
// ============================================================================

`timescale 1ns / 1ps

module clk_wiz_0 (
    input  wire clk_in1,     // 100 MHz
    input  wire reset,       // active-high reset
    output wire clk_out1,    // 25 MHz (actually 100/4)
    output wire locked       // PLL lock indicator
);

    // ---- 100 MHz -> 25 MHz divider (divide by 4) ----
    reg [1:0]  div_cnt;
    reg        clk_out1_reg;
    reg        locked_reg;

    initial begin
        div_cnt      = 2'd0;
        clk_out1_reg = 1'b0;
        locked_reg   = 1'b0;
    end

    always @(posedge clk_in1 or posedge reset) begin
        if (reset) begin
            div_cnt      <= 2'd0;
            clk_out1_reg <= 1'b0;
            locked_reg   <= 1'b0;
        end else begin
            div_cnt <= div_cnt + 1;

            // Toggle output at half the divide ratio -> 100/(2*2) = 25 MHz
            if (div_cnt == 2'd1)
                clk_out1_reg <= ~clk_out1_reg;

            // Assert LOCKED after a few input cycles (no real lock time needed)
            if (div_cnt > 2'd2)
                locked_reg <= 1'b1;
        end
    end

    assign clk_out1 = clk_out1_reg;
    assign locked   = locked_reg;

endmodule

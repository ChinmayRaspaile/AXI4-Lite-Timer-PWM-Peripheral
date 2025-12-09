`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2025 21:05:03
// Design Name: 
// Module Name: fpga_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// fpga_top.sv
// Nexys 4 DDR demo: PWM on LED0 using timer_pwm_core
module fpga_top (
    input  logic clk_in,     // 100 MHz clock on E3
    input  logic rst_n_btn,  // CONNECTED TO BTN_C (active-HIGH on board)
    output logic pwm_led     // CONNECTED TO LED0 (T8)
);

    // Invert active-high button to get an active-low reset
    wire rst_btn = rst_n_btn;       // BTN_C is active-high
    wire rst_n_raw = ~rst_btn;      // now active-low

    // Simple 2-flop reset synchronizer (to clk_in domain)
    logic [1:0] rst_sync_ff;
    logic       rst_sync_n;

    always_ff @(posedge clk_in or negedge rst_n_raw) begin
        if (!rst_n_raw) begin
            rst_sync_ff <= 2'b00;
        end else begin
            rst_sync_ff <= {rst_sync_ff[0], 1'b1};
        end
    end

    assign rst_sync_n = rst_sync_ff[1];

    // Values assuming 100 MHz clock:
    // PERIOD = 50,000,000 cycles => 0.5 s total period
    // DUTY   = 25,000,000 cycles => 50% duty (LED on 0.25 s, off 0.25 s)
    localparam [31:0] PERIOD_VAL = 32'd50_000_000;
    localparam [31:0] DUTY_VAL   = 32'd25_000_000;

    logic dummy_timer_done;
    logic dummy_overflow;

    timer_pwm_core u_core_fpga (
        .clk        (clk_in),
        .rst_n      (rst_sync_n),
        .enable     (1'b1),          // always enabled
        .mode_pwm   (1'b1),          // PWM mode
        .period     (PERIOD_VAL),
        .duty       (DUTY_VAL),
        .pwm_out    (pwm_led),
        .timer_done (dummy_timer_done),
        .overflow   (dummy_overflow)
    );

endmodule

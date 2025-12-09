`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2025 21:01:39
// Design Name: 
// Module Name: timer_pwm_core
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

// timer_pwm_core.sv
module timer_pwm_core (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        enable,
    input  logic        mode_pwm,    // 0 = timer mode, 1 = PWM
    input  logic [31:0] period,
    input  logic [31:0] duty,

    output logic        pwm_out,
    output logic        timer_done,
    output logic        overflow
);

    logic [31:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count      <= 32'd0;
            timer_done <= 1'b0;
            overflow   <= 1'b0;
        end else begin
            timer_done <= 1'b0; // pulse
            overflow   <= 1'b0;

            if (!enable) begin
                count <= 32'd0;
            end else begin
                if (count >= period) begin
                    count      <= 32'd0;
                    timer_done <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end

                // Simple overflow detection
                if (&count) begin
                    overflow <= 1'b1;
                end
            end
        end
    end

    always_comb begin
        if (!enable) begin
            pwm_out = 1'b0;
        end else if (!mode_pwm) begin
            // timer mode: output held low
            pwm_out = 1'b0;
        end else begin
            // PWM: high while count < duty
            pwm_out = (count < duty);
        end
    end

endmodule

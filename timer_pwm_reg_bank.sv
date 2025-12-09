`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2025 20:58:04
// Design Name: 
// Module Name: timer_pwm_reg_bank
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


// timer_pwm_reg_bank.sv
module timer_pwm_reg_bank #(
    parameter ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [31:0]           wr_data,

    input  logic                  rd_en,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [31:0]           rd_data,

    // To core
    output logic                  enable,
    output logic                  mode_pwm,
    output logic [31:0]           period,
    output logic [31:0]           duty,

    // From core
    input  logic                  timer_done,
    input  logic                  overflow
);

    logic [31:0] control_reg; // 0x00
    logic [31:0] status_reg;  // 0x04
    logic [31:0] period_reg;  // 0x08
    logic [31:0] duty_reg;    // 0x0C

    // CONTROL bits:
    // bit0: enable
    // bit1: mode (0=timer, 1=PWM)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= 32'b0;
            status_reg  <= 32'b0;
            period_reg  <= 32'd1000; // defaults
            duty_reg    <= 32'd500;
        end else begin
            // Update status from core
            status_reg[0] <= timer_done;
            status_reg[1] <= overflow;

            if (wr_en) begin
                unique case (wr_addr[3:2])  // word aligned
                    2'b00: control_reg <= wr_data;
                    // You can allow SW to clear status bits if you want:
                    2'b01: status_reg  <= wr_data; 
                    2'b10: period_reg  <= wr_data;
                    2'b11: duty_reg    <= wr_data;
                    default: ;
                endcase
            end
        end
    end

    // Read logic
    always_comb begin
        rd_data = 32'h0;
        if (rd_en) begin
            unique case (rd_addr[3:2])
                2'b00: rd_data = control_reg;
                2'b01: rd_data = status_reg;
                2'b10: rd_data = period_reg;
                2'b11: rd_data = duty_reg;
                default: rd_data = 32'hDEAD_BEEF;
            endcase
        end
    end

    // Signals to core
    assign enable   = control_reg[0];
    assign mode_pwm = control_reg[1];
    assign period   = period_reg;
    assign duty     = duty_reg;

endmodule

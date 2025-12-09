`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2025 20:55:36
// Design Name: 
// Module Name: axi_timer_pwm_top
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

// axi_timer_pwm_top.sv
module axi_timer_pwm_top #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETn,   // active-low reset

    // AXI4-Lite Slave Interface
    input  logic [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  logic                  S_AXI_AWVALID,
    output logic                  S_AXI_AWREADY,

    input  logic [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  logic [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  logic                  S_AXI_WVALID,
    output logic                  S_AXI_WREADY,

    output logic [1:0]            S_AXI_BRESP,
    output logic                  S_AXI_BVALID,
    input  logic                  S_AXI_BREADY,

    input  logic [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  logic                  S_AXI_ARVALID,
    output logic                  S_AXI_ARREADY,

    output logic [DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0]            S_AXI_RRESP,
    output logic                  S_AXI_RVALID,
    input  logic                  S_AXI_RREADY,

    // Outputs
    output logic                  pwm_out,
    output logic                  irq
);

    // Simple internal register interface
    logic                  wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;

    logic                  rd_en;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;

    // Control / status signals to core
    logic                  enable;
    logic                  mode_pwm;
    logic [31:0]           period;
    logic [31:0]           duty;

    logic                  timer_done;
    logic                  overflow;

    // AXI-Lite slave wrapper
    axi_lite_simple_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_axi_if (
        .ACLK         (ACLK),
        .ARESETn      (ARESETn),

        .S_AXI_AWADDR (S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),

        .S_AXI_WDATA  (S_AXI_WDATA),
        .S_AXI_WSTRB  (S_AXI_WSTRB),
        .S_AXI_WVALID (S_AXI_WVALID),
        .S_AXI_WREADY (S_AXI_WREADY),

        .S_AXI_BRESP  (S_AXI_BRESP),
        .S_AXI_BVALID (S_AXI_BVALID),
        .S_AXI_BREADY (S_AXI_BREADY),

        .S_AXI_ARADDR (S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),

        .S_AXI_RDATA  (S_AXI_RDATA),
        .S_AXI_RRESP  (S_AXI_RRESP),
        .S_AXI_RVALID (S_AXI_RVALID),
        .S_AXI_RREADY (S_AXI_RREADY),

        .wr_en        (wr_en),
        .wr_addr      (wr_addr),
        .wr_data      (wr_data),
        .rd_en        (rd_en),
        .rd_addr      (rd_addr),
        .rd_data      (rd_data)
    );

    // Register bank
    timer_pwm_reg_bank #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_reg_bank (
        .clk        (ACLK),
        .rst_n      (ARESETn),

        .wr_en      (wr_en),
        .wr_addr    (wr_addr),
        .wr_data    (wr_data),

        .rd_en      (rd_en),
        .rd_addr    (rd_addr),
        .rd_data    (rd_data),

        // To core
        .enable     (enable),
        .mode_pwm   (mode_pwm),
        .period     (period),
        .duty       (duty),

        // From core
        .timer_done (timer_done),
        .overflow   (overflow)
    );

    // Timer / PWM core
    timer_pwm_core u_core (
        .clk        (ACLK),
        .rst_n      (ARESETn),

        .enable     (enable),
        .mode_pwm   (mode_pwm),
        .period     (period),
        .duty       (duty),

        .pwm_out    (pwm_out),
        .timer_done (timer_done),
        .overflow   (overflow)
    );

    // Simple interrupt: high when timer_done
    assign irq = timer_done;

endmodule

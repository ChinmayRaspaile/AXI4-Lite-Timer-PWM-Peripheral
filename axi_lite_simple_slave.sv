`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2025 20:56:32
// Design Name: 
// Module Name: axi_lite_simple_slave
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

// axi_lite_simple_slave.sv
module axi_lite_simple_slave #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETn,

    // AXI4-Lite slave interface
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

    // Simple register interface
    output logic                  wr_en,
    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [DATA_WIDTH-1:0] wr_data,

    output logic                  rd_en,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    input  logic [DATA_WIDTH-1:0] rd_data
);

    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic [ADDR_WIDTH-1:0] araddr_reg;

    // Write address handshake
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_AWREADY <= 1'b0;
            awaddr_reg    <= '0;
        end else begin
            if (!S_AXI_AWREADY && S_AXI_AWVALID) begin
                S_AXI_AWREADY <= 1'b1;
                awaddr_reg    <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0; // 1-cycle pulse
            end
        end
    end

    // Write data handshake
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_WREADY <= 1'b0;
        end else begin
            if (!S_AXI_WREADY && S_AXI_WVALID) begin
                S_AXI_WREADY <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0; // 1-cycle pulse
            end
        end
    end

    // Simple write strobe (AW + W same cycle - OK for our testbench)
    assign wr_en   = S_AXI_AWREADY & S_AXI_AWVALID &
                     S_AXI_WREADY  & S_AXI_WVALID;
    assign wr_addr = awaddr_reg;
    assign wr_data = S_AXI_WDATA; // ignoring WSTRB for now

    // Write response channel
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00; // OKAY
        end else begin
            if (wr_en && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // Read address handshake
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_ARREADY <= 1'b0;
            araddr_reg    <= '0;
        end else begin
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
                araddr_reg    <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0; // 1-cycle pulse
            end
        end
    end

    // Generate read enable
    assign rd_en   = S_AXI_ARREADY & S_AXI_ARVALID;
    assign rd_addr = araddr_reg;

    // Read data channel
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA  <= '0;
            S_AXI_RRESP  <= 2'b00;
        end else begin
            if (rd_en && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RDATA  <= rd_data;
                S_AXI_RRESP  <= 2'b00;   // OKAY
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule

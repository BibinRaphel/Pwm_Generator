`timescale 1 ns / 1 ps

module axi_pwm_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire  [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire  [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire  [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready,
    
    output reg pwm_out  // PWM output signal
);

// AXI Write/Read Signals
reg [C_S_AXI_DATA_WIDTH-1:0] pwm_duty_cycle;
reg axi_awready;
reg axi_wready;
reg axi_bvalid;
reg [1:0] axi_bresp;
reg axi_arready;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
reg [1:0] axi_rresp;
reg axi_rvalid;

assign s00_axi_awready = axi_awready;
assign s00_axi_wready  = axi_wready;
assign s00_axi_bvalid  = axi_bvalid;
assign s00_axi_bresp   = axi_bresp;
assign s00_axi_arready = axi_arready;
assign s00_axi_rdata   = axi_rdata;
assign s00_axi_rresp   = axi_rresp;
assign s00_axi_rvalid  = axi_rvalid;

// Register Write Process
always @(posedge s00_axi_aclk) begin
    if (!s00_axi_aresetn) begin
        axi_awready <= 0;
        axi_wready <= 0;
        axi_bvalid <= 0;
        pwm_duty_cycle <= 0;
    end else begin
        if (s00_axi_awvalid && !axi_awready)
            axi_awready <= 1;
        else
            axi_awready <= 0;

        if (s00_axi_wvalid && !axi_wready) begin
            axi_wready <= 1;
            pwm_duty_cycle <= s00_axi_wdata[7:0];  // Only take lower 8 bits
        end else begin
            axi_wready <= 0;
        end

        if (s00_axi_awvalid && s00_axi_wvalid && !axi_bvalid)
            axi_bvalid <= 1;
        else if (s00_axi_bready)
            axi_bvalid <= 0;
    end
end

// Read Process
always @(posedge s00_axi_aclk) begin
    if (!s00_axi_aresetn) begin
        axi_arready <= 0;
        axi_rvalid <= 0;
        axi_rdata <= 0;
    end else begin
        if (s00_axi_arvalid && !axi_arready)
            axi_arready <= 1;
        else
            axi_arready <= 0;

        if (s00_axi_arvalid && !axi_rvalid) begin
            axi_rvalid <= 1;
            axi_rdata <= pwm_duty_cycle;
        end else if (s00_axi_rready) begin
            axi_rvalid <= 0;
        end
    end
end

// PWM Generator
localparam PWM_PERIOD = 255;
reg [7:0] counter;

always @(posedge s00_axi_aclk) begin
    if (!s00_axi_aresetn) begin
        counter <= 0;
        pwm_out <= 0;
    end else begin
        if (counter < PWM_PERIOD - 1)
            counter <= counter + 1;
        else
            counter <= 0;

        pwm_out <= (counter < pwm_duty_cycle) ? 1'b1 : 1'b0;
    end
end

endmodule

`timescale 1ns / 1ps

module clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clk,
    input wire reset,
    output reg tick
);

reg [31:0] counter;

always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
        tick <= 0;
    end
    else begin
        tick <= 0;                  // Default

        if(counter == DIVISOR-1) begin
            counter <= 0;
            tick <= 1;              // One clock pulse
        end
        else begin
            counter <= counter + 1;
        end
    end
end

endmodule

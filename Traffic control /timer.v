`timescale 1ns / 1ps

module timer #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             tick,          // 1-second pulse from clock divider
    input  wire             start,         // Enable counting
    input  wire             load,          // Load new duration
    input  wire [WIDTH-1:0] duration,      // Time to count

    output reg              done,          // Pulses high when timer expires
    output reg [WIDTH-1:0]  count          // Current countdown value
);

always @(posedge clk) begin
    if (reset) begin
        count <= 0;
        done  <= 0;
    end
    else begin
        // Default: done is a one-clock pulse
        done <= 0;

        // Load new timer value
        if (load) begin
            count <= duration;
        end

        // Count down once every tick
        else if (start && tick) begin

            if (count > 1) begin
                count <= count - 1;
            end
            else if (count == 1) begin
                count <= 0;
                done  <= 1;
            end

        end
    end
end

endmodule

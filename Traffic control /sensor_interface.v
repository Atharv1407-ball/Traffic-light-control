`timescale 1ns / 1ps

module sensor_interface(
    input  wire clk,
    input  wire reset,

    // Raw vehicle sensor inputs
    input  wire north_sensor,
    input  wire east_sensor,
    input  wire south_sensor,
    input  wire west_sensor,

    // Synchronized outputs
    output reg north_detect,
    output reg east_detect,
    output reg south_detect,
    output reg west_detect
);

    // First synchronization stage
    reg north_ff1, east_ff1, south_ff1, west_ff1;

    always @(posedge clk) begin
        if(reset) begin
            north_ff1   <= 1'b0;
            east_ff1    <= 1'b0;
            south_ff1   <= 1'b0;
            west_ff1    <= 1'b0;

            north_detect <= 1'b0;
            east_detect  <= 1'b0;
            south_detect <= 1'b0;
            west_detect  <= 1'b0;
        end
        else begin
            // Stage 1
            north_ff1 <= north_sensor;
            east_ff1  <= east_sensor;
            south_ff1 <= south_sensor;
            west_ff1  <= west_sensor;

            // Stage 2
            north_detect <= north_ff1;
            east_detect  <= east_ff1;
            south_detect <= south_ff1;
            west_detect  <= west_ff1;
        end
    end

endmodule

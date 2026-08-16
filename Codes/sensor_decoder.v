`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.08.2026 01:00:55
// Design Name: 
// Module Name: sensor_decoder
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


module sensor_decoder(
    input EW_sensor,
    input NS_sensor,
    output reg [1:0] traffic_condition
    );
always@(*) begin
case({EW_sensor,NS_sensor})
2'b00: traffic_condition=2'b00;
2'b01: traffic_condition=2'b01;
2'b10: traffic_condition=2'b10;
2'b11: traffic_condition=2'b11;
default:traffic_condition=2'b11;
endcase
end
endmodule


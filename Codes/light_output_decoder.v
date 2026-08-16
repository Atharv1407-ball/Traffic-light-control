`timescale 1ns / 1ps

module light_output_decode(
    input wire [7:0] state,
    input wire [1:0] emergency_dir,

    output reg NS_red,
    output reg NS_yellow,
    output reg NS_green,

    output reg EW_red,
    output reg EW_yellow,
    output reg EW_green,

    output reg pedestrian_green
);

localparam [7:0]
    NS_GREEN = 8'b00000001,
    NS_RIGHT = 8'b00000010,
    NS_YELLOW = 8'b00000100,
    ALL_RED = 8'b00001000,
    EW_GREEN = 8'b00010000,
    EW_RIGHT = 8'b00100000,
    EW_YELLOW = 8'b01000000,
    EMERGENCY = 8'b10000000;

always@(*)begin
NS_red=1'b1;
NS_yellow=1'b0;
NS_green=1'b0;
EW_red=1'b1;
EW_yellow=1'b0;
EW_green=1'b0;
pedestrian_green=1'b0;

case(state)
NS_GREEN:begin
NS_red=1'b0;
NS_green=1'b1;
end

NS_RIGHT:begin
NS_red=1'b0;
NS_green=1'b1;
end

NS_YELLOW:begin
NS_red=1'b0;
NS_yellow=1'b1;
end

ALL_RED:begin
NS_red=1'b1;
EW_red=1'b1;
end

EW_GREEN:begin
EW_red=1'b0;
EW_green=1'b1;
end

EW_RIGHT:begin
EW_red=1'b0;
EW_green=1'b1;
end

EW_YELLOW:begin
EW_red=1'b0;
EW_yellow=1'b1;
end

EMERGENCY:begin
if(emergency_dir==2'b01)begin
NS_red=1'b0;
NS_green=1'b1;
end
else if(emergency_dir==2'b10)begin
EW_red=1'b0;
EW_green=1'b1;
end
end

default:begin
NS_red=1'b1;
EW_red=1'b1;
end
endcase
end
endmodule

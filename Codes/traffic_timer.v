`timescale 1ns / 1ps

module traffic_timer(
    input wire clk,
    input wire reset,

    input wire [7:0] current_state,

    input wire emergency,
    input wire emergency_restore,

    output reg min_green_done,
    output reg max_green_done,
    output reg right_turn_done,
    output reg yellow_done,
    output reg all_red_done,
//    output reg ped_done,
    output reg emergency_buffer_done,
    output reg emergency_restore_done
);
reg [5:0] timer_count;
reg [5:0] emergency_restore_time;
reg [7:0] previous_state;
reg emergency_seen;
localparam [7:0]
    NS_GREEN  = 8'b00000001,
    NS_RIGHT  = 8'b00000010,
    NS_YELLOW = 8'b00000100,
    ALL_RED   = 8'b00001000,
    EW_GREEN  = 8'b00010000,
    EW_RIGHT  = 8'b00100000,
    EW_YELLOW = 8'b01000000,
    EMERGENCY = 8'b10000000;
always@(posedge clk or posedge reset)begin
    if(reset)begin
        previous_state<=NS_GREEN;
        timer_count<=6'd0;
        emergency_restore_time<=6'd0;
        emergency_seen<=6'd0;
    end
    else begin
        previous_state<=current_state;

        if(current_state != previous_state)
            timer_count<=6'd0;
        else
            timer_count<=timer_count+1'b1;

if(emergency && !emergency_seen)begin
    emergency_seen<=1'b1;

    if(current_state==EW_GREEN || current_state==NS_GREEN)begin
        if(timer_count<=6'd52)
            emergency_restore_time<=6'd55-timer_count-6'd3;
        else
            emergency_restore_time<=6'd0;
    end
end
else if(!emergency)begin
    emergency_seen<=1'b0;
end
end
end
always@(*)begin
    min_green_done = 1'b0;
    max_green_done = 1'b0;
    right_turn_done = 1'b0;
    yellow_done = 1'b0;
    all_red_done = 1'b0;
    emergency_buffer_done = 1'b0;
    emergency_restore_done = 1'b0;
    
//    ped_done=1'b0;
case(current_state)
NS_GREEN,EW_GREEN:begin
if(emergency_restore && timer_count>=emergency_restore_time)begin
    emergency_restore_done=1'b1;
end
else if(timer_count>=6'd55)begin min_green_done=1'b1; max_green_done=1'b1; end

else if (timer_count>=6'd15) begin min_green_done=1'b1; end
end
NS_YELLOW,EW_YELLOW:begin
if(timer_count>=6'd5)begin yellow_done=1'b1; end
 end
NS_RIGHT,EW_RIGHT:begin
if(timer_count>=6'd12)begin right_turn_done=1'b1; end
end
EMERGENCY:begin
if(timer_count>=6'd3)begin emergency_buffer_done=1'b1; end
end
ALL_RED:begin
if(timer_count>=6'd3)begin all_red_done=1'b1; end
end

endcase
end

endmodule

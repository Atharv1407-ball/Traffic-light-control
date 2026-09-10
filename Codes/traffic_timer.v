`timescale 1ns / 1ps

module traffic_timer(
    input wire clk,
    input wire reset,

    input wire [7:0] current_state,
    input wire [7:0] next_state,   // NEW: from traffic_fsm, for same-edge transition detection

    input wire emergency,
    input wire emergency_restore_pending,
    input wire [1:0] emergency_dir,   // 2'b01 = NS was interrupted, 2'b10 = EW was interrupted

    output reg min_green_done,
    output reg max_green_done,
    output reg right_turn_done,
    output reg yellow_done,
    output reg all_red_done,
//    output reg ped_done,
    output reg emergency_buffer_done
);
reg [5:0] timer_count;
reg [5:0] emergency_restore_time;
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
        timer_count<=6'd0;
        emergency_restore_time<=6'd0;
        emergency_seen<=6'd0;
    end
    else begin
        // FIX: reset the counter using next_state vs current_state (both
        // combinationally available on THIS same edge) instead of comparing
        // against a registered previous_state, which only caught up one
        // full cycle after the transition actually happened. That lag let
        // a state's very first cycle run with the PREVIOUS state's leftover
        // count, which could already exceed the new state's own threshold
        // (e.g. 21 leftover counts from a green phase vs. NS_RIGHT's
        // threshold of 12), causing right_turn_done/all_red_done to fire
        // instantly and cut that phase down to a single cycle.
        if(next_state != current_state)
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
    
//    ped_done=1'b0;
case(current_state)
NS_GREEN:begin
    if (timer_count>=6'd15) min_green_done=1'b1;
    // NS's green gets interrupted by an EW emergency (emergency_dir==10).
    // When we're back in NS_GREEN afterward, extend max-green to the saved
    // restore target instead of the normal 55, so NS gets its lost time back.
    if (emergency_restore_pending && emergency_dir==2'b10) begin
        if (timer_count>=emergency_restore_time) max_green_done=1'b1;
    end else begin
        if (timer_count>=6'd55) begin min_green_done=1'b1; max_green_done=1'b1; end
    end
end
EW_GREEN:begin
    if (timer_count>=6'd15) min_green_done=1'b1;
    // EW's green gets interrupted by an NS emergency (emergency_dir==01).
    if (emergency_restore_pending && emergency_dir==2'b01) begin
        if (timer_count>=emergency_restore_time) max_green_done=1'b1;
    end else begin
        if (timer_count>=6'd55) begin min_green_done=1'b1; max_green_done=1'b1; end
    end
end
NS_YELLOW,EW_YELLOW:begin
if(timer_count>=6'd5)begin yellow_done=1'b1; end
 end
NS_RIGHT,EW_RIGHT:begin
if(timer_count>=6'd12)begin right_turn_done=1'b1; end
end
EMERGENCY:begin
// (emergency_buffer_done used to be computed here, but the FSM only ever
// checks it while current_state == ALL_RED to decide whether to leave
// ALL_RED for EMERGENCY. Computing it here made it impossible to ever
// become true: you needed emergency_buffer_done to REACH emergency, but
// it only turned 1'b1 once you were already there - a deadlock that froze
// the whole intersection on all-red for every emergency request. Moved
// below to ALL_RED, alongside all_red_done, using the same 3-count buffer.)
end
ALL_RED:begin
if(timer_count>=6'd3)begin all_red_done=1'b1; emergency_buffer_done=1'b1; end
end

endcase
end

endmodule

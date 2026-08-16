module traffic_fsm (
    input wire       clk,
    input wire       reset,

    // From sensor_decoder.v
    input wire [1:0] traffic_condition,

    // Requests
    input wire       ped_request,
    input wire       emergency,

    // From traffic_timer.v
    input wire       min_green_done,
    input wire       max_green_done,
    input wire       right_turn_done,
    input wire       yellow_done,
    input wire       all_red_done,
    input wire       ped_done,
    input wire emergency_buffer_done,
    input wire [1:0] emergency_direction,
    output reg [1:0] emergency_dir,
    input wire emergency_restore_done,
    output reg emergency_restore,
    // Current one-hot state
    output reg [7:0] current_state
);
reg [7:0] next_state;
reg all_red_to_ew;
reg emergency_pending;
reg emergency_restore_pending;
reg ped_pending;
localparam [7:0]
    NS_GREEN      = 8'b00000001,
    NS_RIGHT      = 8'b00000010,
    NS_YELLOW     = 8'b00000100,
    ALL_RED       = 8'b00001000,
    EW_GREEN      = 8'b00010000,
    EW_RIGHT      = 8'b00100000,
    EW_YELLOW     = 8'b01000000,
    EMERGENCY     = 8'b10000000;
always @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= NS_GREEN;
    else
        current_state <= next_state;
end
always @(posedge clk or posedge reset) begin
if (reset) begin
      emergency_pending <= 1'b0;
        emergency_dir <= 2'b00;
    end
    else begin
        if (emergency) begin
            emergency_pending <= 1'b1;
            emergency_dir <= emergency_direction;
        end
        else if (current_state == EMERGENCY) begin
            emergency_pending <= 1'b0;
        end
    end
end
always @(posedge clk or posedge reset) begin
if (reset)
all_red_to_ew <= 1'b0;
else if (current_state == NS_YELLOW && yellow_done)
all_red_to_ew <= 1'b1;
else if (current_state == EW_YELLOW && yellow_done)
all_red_to_ew <= 1'b0;
end
always @(posedge clk or posedge reset) begin
    if (reset)
        emergency_restore_pending <= 1'b0;
    else if (current_state == EMERGENCY && !emergency)
        emergency_restore_pending <= 1'b1;
    else if (emergency_restore_done)
        emergency_restore_pending <= 1'b0;
end
//always @(posedge clk or posedge reset) begin
//    if (reset)
//        ped_pending <= 1'b0;
//    else if (ped_request)
//        ped_pending <= 1'b1;
//    else if (ped_done)
//        ped_pending <= 1'b0;
//end
always@(*)begin
next_state=current_state;
emergency_restore = 1'b0;
case(current_state)
NS_GREEN:begin
if (emergency_restore_pending && emergency_dir == 2'b10) begin
        emergency_restore = 1'b1;
        next_state = NS_GREEN;
    end

else if(!min_green_done)begin
next_state=NS_GREEN;
end
else if (emergency_pending) begin
        next_state = NS_YELLOW; end
else if(max_green_done)begin 
next_state=NS_YELLOW;
end
else begin
case(traffic_condition)
2'b00:next_state=NS_GREEN;
2'b01:next_state=NS_GREEN;
2'b10:next_state=NS_RIGHT;
2'b11:next_state=NS_GREEN;
endcase
end
end
NS_YELLOW:begin
if(!yellow_done)begin
next_state=NS_YELLOW;
end

else begin
next_state=ALL_RED;

end
end
NS_RIGHT:begin
if(!right_turn_done)begin
next_state=NS_RIGHT;
end
else begin
next_state=NS_YELLOW;
end
end
ALL_RED: begin
    if(emergency_pending) begin
        if(emergency_buffer_done)
            next_state = EMERGENCY;
        else
            next_state = ALL_RED;
    end
    else begin
        if(!all_red_done)
            next_state = ALL_RED;
        else if(all_red_to_ew)
            next_state = EW_GREEN;
        else
            next_state = NS_GREEN;
    end
end
EW_GREEN:begin
if (emergency_restore_pending && emergency_dir == 2'b01) begin
        emergency_restore = 1'b1;
        next_state = EW_GREEN;
    end
else if(!min_green_done)begin
next_state=EW_GREEN;
end
else if (emergency_pending) begin
        next_state = EW_YELLOW; end
else if(max_green_done)begin 
next_state=EW_YELLOW;
end
else begin
case(traffic_condition)
2'b00:next_state=EW_GREEN;
2'b01:next_state=EW_RIGHT;
2'b10:next_state=EW_GREEN;
2'b11:next_state=EW_GREEN;
endcase
end
end
EW_RIGHT:begin
if(!right_turn_done)begin
next_state=EW_RIGHT;
end
else begin
next_state=EW_YELLOW;
end
end
EW_YELLOW:begin
if(!yellow_done)begin
next_state=EW_YELLOW;
end
else begin
next_state=ALL_RED;

end
end
EMERGENCY: begin
    if(emergency) begin
        next_state = EMERGENCY;
    end
    else if(emergency_dir == 2'b01) begin
        next_state = NS_YELLOW;
    end
    else if(emergency_dir == 2'b10) begin
        next_state = EW_YELLOW;
    end
    else begin
        next_state = NS_YELLOW;
    end
end
default: begin
    next_state = NS_GREEN;
end


endcase
end
endmodule

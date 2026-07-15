module traffic_fsm (
    input wire clk,
    input wire reset,
    input wire timer_done,
    input wire north_detect,
    input wire south_detect,
    input wire east_detect,
    input wire west_detect,
    input wire emergency,
    input wire [1:0] emergency_dir,
    
    output reg [2:0] state,
    output reg timer_load,
    output reg [4:0] timer_value,
    
    output reg NS_red, NS_yellow, NS_green,
    output reg SS_red, SS_yellow, SS_green,
    output reg ES_red, ES_yellow, ES_green,
    output reg WS_red, WS_yellow, WS_green,
    output reg NR_green, SR_green, ER_green, WR_green,
    output reg pedestrian_green
);

    // Timing Parameters
    parameter STRAIGHT_TIME = 5'd30;
    parameter RIGHT_TIME    = 5'd10;
    parameter PED_TIME      = 5'd15;

    // FSM State Encodings
    localparam S0          = 3'd0; // North-South Straight Green
    localparam S1          = 3'd1; // North Right Turn
    localparam S2          = 3'd2; // South Right Turn
    localparam S3          = 3'd3; // East-West Straight Green
    localparam S4          = 3'd4; // East Right Turn
    localparam S5          = 3'd5; // West Right Turn
    localparam S6          = 3'd6; // Pedestrian
    localparam S_EMERGENCY = 3'd7; // Emergency State

    reg [2:0] next_state;
    reg [2:0] saved_state;

    // =========================================================
    // 1. Sequential Logic: State Register & Timer Load Control
    // =========================================================
    always @(posedge clk) begin
        if (reset) begin
            state       <= S0;
            saved_state <= S0;
            timer_load  <= 1'b0;
        end else begin
            timer_load <= 1'b0; // Default to 0 ensures a clean 1-cycle pulse
            
            if (state == S_EMERGENCY) begin
                // Hold in emergency until input clears
                if (!emergency) begin
                    state      <= saved_state; // Restore the phase we were supposed to enter
                    timer_load <= 1'b1;        // Pulse timer load for the restored state
                end
            end else begin
                // Normal operational sequence
                // Wait for the current active phase to finish to prevent skipping/repeating
                if (state != next_state) begin
                    if (emergency) begin
                        // Phase complete. Save the NEXT intended state and go to emergency
                        saved_state <= state; 
                        state       <= S_EMERGENCY;
                        timer_load  <= 1'b1;
                    end else begin
                        // Standard sequential progression
                        state       <= next_state;
                        timer_load  <= 1'b1;
                    end
                end
            end
        end
    end

    // =========================================================
    // 2. Combinational Logic: Next-State Logic (Adaptive Skip)
    // =========================================================
    always @(*) begin
        next_state = state; // Default behavior: remain in current state
        case (state)
            // Camera Skip Logic:
            // Since there is only one timer (timer_done), we cannot measure a separate 
            // "minimum green" and "maximum green" time. 
            // - To prevent deadlock (getting stuck forever waiting for a vehicle to leave), 
            //   the FSM MUST transition when timer_done is high.
            // - To safely utilize the sensors without getting stuck, we immediately skip 
            //   the phase ONLY if the lane is completely empty (!detect). 
            S0: if (timer_done || !(north_detect || south_detect)) next_state = S1;
            S1: if (timer_done || !north_detect)                   next_state = S2;
            S2: if (timer_done || !south_detect)                   next_state = S3;
            S3: if (timer_done || !(east_detect || west_detect))   next_state = S4;
            S4: if (timer_done || !east_detect)                    next_state = S5;
            S5: if (timer_done || !west_detect)                    next_state = S6;
            S6: if (timer_done)                                    next_state = S0; // Pedestrian holds full time
            S_EMERGENCY: next_state = S_EMERGENCY; // Exit handled by sequential logic
            default: next_state = S0;
        endcase
    end

    // =========================================================
    // 3. Combinational Logic: Moore Outputs
    // =========================================================
    always @(*) begin
        // Default assignments: All vehicle signals RED, pedestrians RED
        // This guarantees no inferred latches or multiple drivers.
        NS_red = 1'b1; NS_yellow = 1'b0; NS_green = 1'b0;
        SS_red = 1'b1; SS_yellow = 1'b0; SS_green = 1'b0;
        ES_red = 1'b1; ES_yellow = 1'b0; ES_green = 1'b0;
        WS_red = 1'b1; WS_yellow = 1'b0; WS_green = 1'b0;
        
        NR_green = 1'b0; 
        SR_green = 1'b0; 
        ER_green = 1'b0; 
        WR_green = 1'b0;
        
        pedestrian_green = 1'b0;
        timer_value      = 5'd0;

        case (state)
            S0: begin // North-South Straight Green
                NS_red = 1'b0; NS_green = 1'b1;
                SS_red = 1'b0; SS_green = 1'b1;
                timer_value = STRAIGHT_TIME;
            end
            S1: begin // North Right Turn
                NR_green = 1'b1;
                timer_value = RIGHT_TIME;
            end
            S2: begin // South Right Turn
                SR_green = 1'b1;
                timer_value = RIGHT_TIME;
            end
            S3: begin // East-West Straight Green
                ES_red = 1'b0; ES_green = 1'b1;
                WS_red = 1'b0; WS_green = 1'b1;
                timer_value = STRAIGHT_TIME;
            end
            S4: begin // East Right Turn
                ER_green = 1'b1;
                timer_value = RIGHT_TIME;
            end
            S5: begin // West Right Turn
                WR_green = 1'b1;
                timer_value = RIGHT_TIME;
            end
            S6: begin // Pedestrian Crossing (All vehicles RED)
                pedestrian_green = 1'b1;
                timer_value = PED_TIME;
            end
            S_EMERGENCY: begin 
                // Emergency Mode: Timer held disabled. 
                timer_value = 5'd0; 
                // ONLY requested direction gets GREEN, all conflicting stay RED by default
                case (emergency_dir)
                    2'b00: begin NS_green = 1'b1; NS_red = 1'b0; end
                    2'b01: begin SS_green = 1'b1; SS_red = 1'b0; end
                    2'b10: begin ES_green = 1'b1; ES_red = 1'b0; end
                    2'b11: begin WS_green = 1'b1; WS_red = 1'b0; end
                    default: ; // Retains all-RED default for safety
                endcase
            end
            default: begin
                timer_value = 5'd0;
            end
        endcase
    end

endmodule

`timescale 1ns / 1ps

module traffic_controller_top (
    // System Signals
    input wire clk,
    input wire reset,
    
    // Raw Vehicle Sensor Inputs
    input wire north_sensor,
    input wire south_sensor,
    input wire east_sensor,
    input wire west_sensor,
    
    // Pedestrian Request Input
    input wire pedestrian_req,
    
    // Emergency Control Inputs
    input wire emergency,
    input wire [1:0] emergency_dir,
    
    // North Straight Traffic Lights
    output wire NS_red,
    output wire NS_yellow,
    output wire NS_green,
    
    // South Straight Traffic Lights
    output wire SS_red,
    output wire SS_yellow,
    output wire SS_green,
    
    // East Straight Traffic Lights
    output wire ES_red,
    output wire ES_yellow,
    output wire ES_green,
    
    // West Straight Traffic Lights
    output wire WS_red,
    output wire WS_yellow,
    output wire WS_green,
    
    // Right Turn Green Lights
    output wire NR_green,
    output wire SR_green,
    output wire ER_green,
    output wire WR_green,
    
    // Pedestrian Crossing Light
    output wire pedestrian_green
);

    // =========================================================
    // Internal Interconnect Wires
    // =========================================================
    
    // Clock divider to Timer
    wire clk_tick;
    
    // Sensor Interface to FSM
    wire north_detect;
    wire south_detect;
    wire east_detect;
    wire west_detect;
    
    // FSM to Timer
    wire timer_load;
    wire [4:0] timer_value;
    
    // Timer to FSM
    wire timer_done;
    
    // FSM Debug/State Monitor Wire
    wire [2:0] current_state;

    // =========================================================
    // Module Instantiations
    // =========================================================

    // 1. Clock Divider
    // Divides the high-frequency system clock down to a 1Hz (or desired) 
    // tick pulse for the timer module.
    clock_divider u_clock_divider (
        .clk    (clk),
        .reset  (reset),
        .tick   (clk_tick)
    );

    // 2. Timer Module
    // Counts down the duration provided by the FSM. Decrements on every 
    // 'tick' from the clock divider. Asserts 'done' when it reaches 0.
    // Instantiated with WIDTH = 5 to match the FSM timer_value width.
    timer #(
        .WIDTH (5)
    ) u_timer (
        .clk      (clk),
        .reset    (reset),
        .tick     (clk_tick),
        .start    (1'b1),        // Timer always runs when loaded
        .load     (timer_load),  // Connected from FSM timer_load
        .duration (timer_value), // Connected from FSM timer_value
        .done     (timer_done),  // Connected to FSM timer_done
        .count    ()             // Left unconnected as it's not needed by FSM
    );

    // 3. Sensor Interface
    // Debounces and processes raw sensor inputs from the intersection to 
    // provide clean, stable detection signals for the FSM's adaptive skip logic.
    sensor_interface u_sensor_interface (
        .clk          (clk),
        .reset        (reset),
        .north_sensor (north_sensor),
        .south_sensor (south_sensor),
        .east_sensor  (east_sensor),
        .west_sensor  (west_sensor),
        .north_detect (north_detect),
        .south_detect (south_detect),
        .east_detect  (east_detect),
        .west_detect  (west_detect)
    );

    // 4. Traffic Finite State Machine (FSM)
    // The core controller determining states, outputting traffic light signals, 
    // checking sensors for skips, and handling emergency preemptions.
    traffic_fsm u_traffic_fsm (
        .clk              (clk),
        .reset            (reset),
        .timer_done       (timer_done),
        .north_detect     (north_detect),
        .south_detect     (south_detect),
        .east_detect      (east_detect),
        .west_detect      (west_detect),
        .pedestrian_req   (pedestrian_req),
        .emergency        (emergency),
        .emergency_dir    (emergency_dir),
        
        .state            (current_state),
        .timer_load       (timer_load),
        .timer_value      (timer_value),
        
        .NS_red           (NS_red), 
        .NS_yellow        (NS_yellow), 
        .NS_green         (NS_green),
        
        .SS_red           (SS_red), 
        .SS_yellow        (SS_yellow), 
        .SS_green         (SS_green),
        
        .ES_red           (ES_red), 
        .ES_yellow        (ES_yellow), 
        .ES_green         (ES_green),
        
        .WS_red           (WS_red), 
        .WS_yellow        (WS_yellow), 
        .WS_green         (WS_green),
        
        .NR_green         (NR_green), 
        .SR_green         (SR_green), 
        .ER_green         (ER_green), 
        .WR_green         (WR_green),
        
        .pedestrian_green (pedestrian_green)
    );

endmodule

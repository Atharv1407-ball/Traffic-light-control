`timescale 1s / 1ms

module testbenchi;

reg clk;
reg reset;

reg EW_sensor;
reg NS_sensor;

reg emergency_NS;
reg emergency_EW;

reg ped_NS;
reg ped_EW;

reg maintenance_mode;

wire NS_red;
wire NS_yellow;
wire NS_green;

wire EW_red;
wire EW_yellow;
wire EW_green;

wire pedestrian_green;


// DUT
traffic_system uut(

    .clk(clk),
    .reset(reset),

    .EW_sensor(EW_sensor),
    .NS_sensor(NS_sensor),

    .emergency_NS(emergency_NS),
    .emergency_EW(emergency_EW),

    .ped_NS(ped_NS),
    .ped_EW(ped_EW),

    .maintenance_mode(maintenance_mode),

    .NS_red(NS_red),
    .NS_yellow(NS_yellow),
    .NS_green(NS_green),

    .EW_red(EW_red),
    .EW_yellow(EW_yellow),
    .EW_green(EW_green),

    .pedestrian_green(pedestrian_green)
);


// 1 Hz clock
always #0.5 clk = ~clk;


initial begin

    // Initial values
    clk = 1'b0;
    reset = 1'b1;

    EW_sensor = 1'b0;
    NS_sensor = 1'b0;

    emergency_NS = 1'b0;
    emergency_EW = 1'b0;

    ped_NS = 1'b0;
    ped_EW = 1'b0;

    maintenance_mode = 1'b0;


    // Reset
    #1;
    reset = 1'b0;


    // --------------------------------
    // TEST 1: NS traffic
    // --------------------------------

    NS_sensor = 1'b1;
    EW_sensor = 1'b0;

    // Let NS green run
    #20;


    // --------------------------------
    // TEST 2: EW traffic
    // --------------------------------

    NS_sensor = 1'b0;
    EW_sensor = 1'b1;

    #20;


    // --------------------------------
    // TEST 3: NS emergency
    // --------------------------------

    emergency_NS = 1'b1;

    #5;

    emergency_NS = 1'b0;

    // Allow emergency sequence
    #15;


    // --------------------------------
    // TEST 4: EW emergency
    // --------------------------------

    emergency_EW = 1'b1;

    #5;

    emergency_EW = 1'b0;

    #15;


    // --------------------------------
    // TEST 5: Both sensors active
    // --------------------------------

    NS_sensor = 1'b1;
    EW_sensor = 1'b1;

    #20;


    // --------------------------------
    // TEST 6: No traffic
    // --------------------------------

    NS_sensor = 1'b0;
    EW_sensor = 1'b0;

    #20;


    $finish;

end

endmodule

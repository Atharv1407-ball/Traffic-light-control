
# Smart Traffic Signal Controller using Verilog HDL

## Project Overview

Traffic congestion is a common problem in urban areas, and conventional traffic lights often operate on fixed timings regardless of the actual traffic density. The aim of this project is to design a smart traffic signal controller using Verilog HDL that can adapt to vehicle presence, provide dedicated right-turn phases, handle pedestrian crossings, and prioritize emergency vehicles.

The controller is implemented as a Finite State Machine (FSM) and follows a modular design approach, making it easier to understand, verify, and modify. The entire system was simulated and verified in Xilinx Vivado.

---

## Objectives

- Design a modular traffic light controller using Verilog HDL.
- Implement a Finite State Machine (FSM) to control traffic flow.
- Reduce unnecessary waiting time by skipping empty lanes.
- Support pedestrian crossings.
- Provide emergency vehicle priority without disrupting the overall traffic sequence.
- Verify the complete design through simulation.

---

## Working Principle

The controller follows a predefined sequence of traffic phases.

```
North-South Straight
        ↓
North Right Turn
        ↓
South Right Turn
        ↓
East-West Straight
        ↓
East Right Turn
        ↓
West Right Turn
        ↓
Pedestrian Crossing
        ↓
Repeat
```

Each state remains active for a predefined duration controlled by a timer. Vehicle sensors continuously monitor each lane. If a lane has no vehicles, the controller skips that phase instead of wasting time.

Whenever an emergency signal is detected, the controller temporarily suspends normal operation and immediately switches to an emergency mode where only the requested direction receives a green signal. Once the emergency ends, the controller resumes from the appropriate state instead of restarting the entire sequence.

---

## Project Modules

The design is divided into independent modules.

### 1. Traffic FSM (`traffic_fsm.v`)

This is the heart of the project.

It is responsible for:

- Controlling the traffic sequence
- Generating traffic light outputs
- Selecting timer durations
- Handling emergency mode
- Processing pedestrian requests
- Deciding state transitions

---

### 2. Timer (`timer.v`)

The timer module generates the delay required for every traffic phase.

Functions include:

- Loading new timer values
- Counting clock ticks
- Generating the `timer_done` signal

---

### 3. Clock Divider (`clock_divider.v`)

Since FPGA clocks operate at very high frequencies, the timer cannot directly use the system clock.

The clock divider converts the high-frequency clock into a slower timing pulse suitable for traffic signal timing.

---

### 4. Sensor Interface (`sensor_interface.v`)

This module receives raw sensor inputs from all four roads and generates stable detection signals for the FSM.

It acts as the interface between the traffic sensors and the controller.

---

### 5. Top Module (`traffic_controller_top.v`)

The top module integrates all the individual components into a complete traffic control system.

It connects:

- Clock Divider
- Timer
- Sensor Interface
- Traffic FSM

---

### 6. Testbench (`tb_traffic_controller.v`)

A comprehensive testbench was developed to verify the complete functionality of the controller.

The simulation checks:

- Reset operation
- Complete traffic cycle
- Vehicle detection logic
- Lane skipping
- Pedestrian crossing
- Emergency vehicle handling
- Recovery after emergency
- Continuous operation over multiple cycles

---

## Inputs

| Signal | Description |
|---------|-------------|
| clk | System clock |
| reset | System reset |
| north_sensor | North lane vehicle sensor |
| south_sensor | South lane vehicle sensor |
| east_sensor | East lane vehicle sensor |
| west_sensor | West lane vehicle sensor |
| pedestrian_req | Pedestrian crossing request |
| emergency | Emergency mode enable |
| emergency_dir | Emergency vehicle direction |

---

## Outputs

### Straight Traffic Lights

- North Signal
- South Signal
- East Signal
- West Signal

Each signal consists of:

- Red
- Yellow
- Green

### Right Turn Signals

- North Right
- South Right
- East Right
- West Right

### Pedestrian Signal

- Pedestrian Green

---

## FSM States

| State | Description |
|--------|-------------|
| S0 | North-South Straight |
| S1 | North Right Turn |
| S2 | South Right Turn |
| S3 | East-West Straight |
| S4 | East Right Turn |
| S5 | West Right Turn |
| S6 | Pedestrian Crossing |
| S7 | Emergency Mode |

---

## Timing Parameters

| Parameter | Value |
|-----------|-------|
| Straight Green | 30 s |
| Right Turn | 10 s |
| Pedestrian | 15 s |

The timings are parameterized and can be changed easily without modifying the FSM logic.

---

## Features Implemented

- Four-way traffic control
- Moore Finite State Machine
- Dedicated right-turn phases
- Pedestrian crossing support
- Emergency vehicle priority
- Sensor-based lane skipping
- Parameterized timing
- Modular Verilog architecture
- Fully synthesizable RTL
- Comprehensive simulation and verification

---

## Software Used

- Xilinx Vivado
- Verilog HDL

---

## Future Improvements

Some features that can be added in future versions include:

- Yellow transition states between traffic phases
- Left-turn signal control
- Dynamic traffic timing based on vehicle count
- Camera-based vehicle detection
- FPGA hardware implementation
- IoT-based remote monitoring
- AI-assisted traffic optimization

---

## Conclusion

This project demonstrates the implementation of a smart traffic signal controller using Verilog HDL. Instead of relying on fixed traffic timings, the controller adapts to real-time vehicle detection, improving traffic flow while also supporting pedestrian crossings and emergency vehicle priority. The modular design makes the system easier to test, maintain, and extend with additional features in the future.

Although simplified for academic purposes, the architecture closely follows the design principles used in real digital traffic control systems and provides a solid foundation for FPGA implementation and further research.

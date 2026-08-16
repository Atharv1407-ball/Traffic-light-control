# Adaptive Traffic Cross-Section Signal Controller

A modular Verilog HDL implementation of an adaptive traffic intersection controller with sensor-based traffic selection, emergency vehicle priority, emergency buffering, emergency restoration, timed traffic phases, right-turn phases, and decoded traffic-light outputs.

The design is written as a collection of independent RTL modules and integrated through a top-level `traffic_system` module.

> **Current design status:** The main traffic FSM, timer, emergency controller, sensor decoder, light decoder, and top-level integration are implemented. Pedestrian handling is currently reserved/not active in the FSM, and the `priority_arbiter` is currently an independent module whose `grant` output is not used by the main FSM.

---

## 1. Project Overview

The controller manages a two-direction intersection:

- **NS** = North-South traffic
- **EW** = East-West traffic

The main controller is an **8-state one-hot FSM**.

### FSM states

| State | Encoding | Purpose |
|---|---|---|
| `NS_GREEN` | `00000001` | NS traffic proceeds |
| `NS_RIGHT` | `00000010` | NS right-turn phase |
| `NS_YELLOW` | `00000100` | NS yellow transition |
| `ALL_RED` | `00001000` | Both directions stopped |
| `EW_GREEN` | `00010000` | EW traffic proceeds |
| `EW_RIGHT` | `00100000` | EW right-turn phase |
| `EW_YELLOW` | `01000000` | EW yellow transition |
| `EMERGENCY` | `10000000` | Emergency vehicle priority |

The FSM state is represented using an 8-bit one-hot vector rather than a binary state number.

---

# 2. System Architecture

The complete design is organized as:

```text
                         ┌─────────────────────┐
EW_sensor ──────────────►│                     │
NS_sensor ──────────────►│   sensor_decoder    │
                         └──────────┬──────────┘
                                    │
                                    │ traffic_condition
                                    ▼
                            ┌────────────────┐
                            │                │
emergency_NS ──────────────►│                │
emergency_EW ──────────────►│ traffic_fsm    │
                            │                │
                            └───────┬────────┘
                                    │
                              current_state
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
            ┌──────────────┐               ┌───────────────────┐
            │traffic_timer │               │light_output_decode│
            └──────┬───────┘               └─────────┬─────────┘
                   │                                  │
             done signals                             │
                   │                                  ▼
                   └───────────────────────►     NS/EW lights


emergency_NS ──┐
               │
emergency_EW ──┼──► emergency_controller
               │            │
maintenance ───┘            │ emergency_active
                            │ emergency_direction
                            ▼
                       traffic_fsm
```

The main feedback path is:

```text
traffic_fsm
     │
     │ current_state
     ▼
traffic_timer
     │
     │ timing completion signals
     └──────────────► traffic_fsm
```

Emergency restoration adds another feedback path:

```text
traffic_fsm
     │
     │ emergency_restore
     ▼
traffic_timer
     │
     │ emergency_restore_done
     ▼
traffic_fsm
```

---

# 3. Module Structure

The repository contains the following main RTL modules:

```text
traffic_system.v
traffic_fsm.v
traffic_timer.v
sensor_decoder.v
emergency_controller.v
light_output_decode.v
priority_arbiter.v
traffic_system_tb.v
```

---

# 4. Top-Level Module

## `traffic_system.v`

This is the integration module.

It does not contain the main control algorithm. Its purpose is to connect the individual modules together.

### Inputs

```verilog
input wire clk
input wire reset

input wire EW_sensor
input wire NS_sensor

input wire emergency_NS
input wire emergency_EW

input wire ped_NS
input wire ped_EW

input wire maintenance_mode
```

### Outputs

```verilog
output wire NS_red
output wire NS_yellow
output wire NS_green

output wire EW_red
output wire EW_yellow
output wire EW_green

output wire pedestrian_green
```

### Top-level connections

The top level connects:

```text
sensor_decoder
        ↓
traffic_condition
        ↓
traffic_fsm
        ↓
current_state
        ├──────────────► light_output_decode
        │
        └──────────────► traffic_timer
                              │
                              └── done signals ──► traffic_fsm
```

The emergency controller is connected separately:

```text
emergency_NS
emergency_EW
maintenance_mode
        │
        ▼
emergency_controller
        │
        ├── emergency_active
        └── emergency_direction
                    │
                    ▼
               traffic_fsm
```

---

# 5. Sensor Decoder

## `sensor_decoder.v`

The sensor decoder converts the two physical traffic sensors into a 2-bit traffic condition.

### Inputs

```verilog
EW_sensor
NS_sensor
```

### Output

```verilog
traffic_condition[1:0]
```

The encoding is:

| `EW_sensor` | `NS_sensor` | `traffic_condition` |
|---:|---:|---|
| 0 | 0 | `00` |
| 0 | 1 | `01` |
| 1 | 0 | `10` |
| 1 | 1 | `11` |

The FSM interprets these values according to the current direction.

For example, in `NS_GREEN`:

```text
00 → remain NS_GREEN
01 → remain NS_GREEN
10 → NS_RIGHT
11 → remain NS_GREEN
```

In `EW_GREEN`:

```text
00 → remain EW_GREEN
01 → EW_RIGHT
10 → remain EW_GREEN
11 → remain EW_GREEN
```

---

# 6. Main Traffic FSM

## `traffic_fsm.v`

This is the central control module.

It is responsible for deciding **which traffic phase should happen next**.

### Inputs

```verilog
clk
reset

traffic_condition

ped_request
emergency

min_green_done
max_green_done
right_turn_done
yellow_done
all_red_done
ped_done

emergency_buffer_done
emergency_direction
emergency_restore_done
```

### Outputs

```verilog
emergency_dir
emergency_restore
current_state
```

---

## FSM State Flow

The normal traffic path is:

```text
             ┌──────────────┐
             │  NS_GREEN    │
             └──────┬───────┘
                    │
              right turn needed
                    │
                    ▼
             ┌──────────────┐
             │  NS_RIGHT    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │  NS_YELLOW   │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │   ALL_RED    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │  EW_GREEN    │
             └──────┬───────┘
                    │
              right turn needed
                    │
                    ▼
             ┌──────────────┐
             │  EW_RIGHT    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │  EW_YELLOW   │
             └──────┬───────┘
                    │
                    ▼
                 ALL_RED
```

`ALL_RED` uses `all_red_to_ew` to remember which direction should receive green after the transition.

---

# 7. Emergency Handling

Emergency handling is intentionally separated from normal traffic decisions.

## Emergency controller

### Inputs

```verilog
emergency_NS
emergency_EW
maintenance_mode
```

### Outputs

```verilog
emergency_active
emergency_override
emergency_direction
```

Direction encoding:

```text
01 = NS emergency
10 = EW emergency
00 = no emergency
```

Emergency priority is higher than normal traffic operation.

---

## Emergency sequence

Suppose NS traffic is currently green and an NS emergency arrives:

```text
NS_GREEN
   ↓
NS_YELLOW
   ↓
ALL_RED
   ↓
EMERGENCY
```

The FSM waits for the emergency buffer timer before entering the emergency state.

The emergency state then gives the requested direction green.

For example:

```text
emergency_dir = 01
        ↓
NS gets green
```

or:

```text
emergency_dir = 10
        ↓
EW gets green
```

---

# 8. Emergency Restore

Emergency restoration is one of the more important parts of the design.

The objective is to avoid simply restarting the interrupted green phase from zero.

For example, suppose:

```text
Normal NS green = 55 s maximum

Emergency occurs after 30 s
```

The timer records the point at which the emergency happened.

The restoration time is calculated as:

```text
remaining green time = 55 - elapsed green time - 3
```

The extra 3 seconds account for the emergency transition/buffer.

The calculated value is stored in:

```verilog
emergency_restore_time
```

The timer only captures this value once per emergency using:

```verilog
emergency_seen
```

This prevents the saved restoration time from continuously changing while the emergency signal remains asserted.

---

## Restore handshake

The FSM generates:

```verilog
emergency_restore = 1'b1;
```

This tells the timer:

> The controller is currently restoring the interrupted green phase. Use the saved restoration timing.

The timer then generates:

```verilog
emergency_restore_done
```

when the restoration time has elapsed.

The FSM then exits restoration mode.

The signal flow is:

```text
             FSM
              │
              │ emergency_restore
              ▼
            Timer
              │
              │ emergency_restore_done
              ▼
             FSM
```

---

# 9. Timer Module

## `traffic_timer.v`

The timer generates all timing-completion signals required by the FSM.

### Inputs

```verilog
clk
reset
current_state

emergency
emergency_restore
```

### Outputs

```verilog
min_green_done
max_green_done
right_turn_done
yellow_done
all_red_done
emergency_buffer_done
emergency_restore_done
```

---

## Timing Values

| Function | Time |
|---|---:|
| Minimum green | 15 counts |
| Maximum green | 55 counts |
| Right turn | 12 counts |
| Yellow | 5 counts |
| All-red | 3 counts |
| Emergency buffer | 3 counts |
| Emergency restore | Variable |

The timer uses:

```verilog
timer_count
```

to count time spent in the current FSM state.

---

## Previous State Detection

The timer contains:

```verilog
previous_state
```

When:

```verilog
current_state != previous_state
```

the timer resets:

```verilog
timer_count <= 6'd0;
```

Otherwise it increments:

```verilog
timer_count <= timer_count + 1'b1;
```

This allows every FSM state to have its own independent timing period.

---

# 10. Light Output Decoder

## `light_output_decode.v`

This module converts the FSM state into actual traffic-light outputs.

### Inputs

```verilog
state[7:0]
emergency_dir[1:0]
```

### Outputs

```verilog
NS_red
NS_yellow
NS_green

EW_red
EW_yellow
EW_green

pedestrian_green
```

The default condition is safe:

```text
NS = RED
EW = RED
```

---

## Example outputs

### NS green

```text
NS = GREEN
EW = RED
```

### NS yellow

```text
NS = YELLOW
EW = RED
```

### EW green

```text
NS = RED
EW = GREEN
```

### EW yellow

```text
NS = RED
EW = YELLOW
```

### ALL_RED

```text
NS = RED
EW = RED
```

### Emergency

If:

```text
emergency_dir = 01
```

then:

```text
NS = GREEN
EW = RED
```

If:

```text
emergency_dir = 10
```

then:

```text
NS = RED
EW = GREEN
```

---

# 11. Priority Arbiter

## `priority_arbiter.v`

The arbiter provides a priority classification of requests.

### Inputs

```verilog
emergency_NS
emergency_EW
ped_NS
ped_EW
traffic_condition
```

### Output

```verilog
grant[2:0]
```

### Grant encoding

```text
000 = No request
001 = NS traffic
010 = EW traffic
011 = NS pedestrian
100 = EW pedestrian
101 = NS emergency
110 = EW emergency
111 = Reserved
```

The priority order is:

```text
Emergency
    ↓
Pedestrian
    ↓
Normal traffic
```

### Current integration status

The current `traffic_system` does **not use `grant` as an FSM input**.

The main FSM currently receives:

```text
traffic_condition
emergency
emergency_direction
ped_request
```

directly.

Therefore, the arbiter is currently an independent request-priority block rather than part of the active FSM decision path.

---

# 12. Pedestrian Inputs

The top-level currently exposes:

```verilog
ped_NS
ped_EW
```

and the FSM has:

```verilog
ped_request
ped_done
ped_pending
```

However, the actual pedestrian sequential logic is currently commented out.

Therefore:

> **Pedestrian functionality is reserved but not active in the current controller behavior.**

This was intentionally left out rather than forcing a poorly-defined pedestrian transition into the FSM.

The output:

```verilog
pedestrian_green
```

also remains available in the light decoder for future implementation.

---

# 13. Reset Behavior

The FSM uses an asynchronous reset:

```verilog
always @(posedge clk or posedge reset)
```

When reset is asserted:

```text
current_state → NS_GREEN
```

The timer and emergency-related registers are also reset.

This gives the controller a deterministic starting state.

---

# 14. Testbench

## `traffic_system_tb.v`

The testbench drives the external inputs of the complete `traffic_system`.

It tests:

1. Reset
2. NS traffic
3. EW traffic
4. NS emergency
5. EW emergency
6. Both sensors active
7. No traffic

The main signals to observe in simulation are:

```text
current_state
traffic_condition

emergency_active
emergency_direction
emergency_restore
emergency_restore_done

min_green_done
max_green_done
right_turn_done
yellow_done
all_red_done
emergency_buffer_done

NS_red
NS_yellow
NS_green

EW_red
EW_yellow
EW_green
```

---

# 15. Important Clock Assumption

The current timer counts clock edges directly.

Therefore, the design currently assumes:

```text
1 clock count ≈ 1 second
```

for the timing values to literally represent seconds.

For example:

```text
15 counts → 15 seconds
55 counts → 55 seconds
```

If the final FPGA board uses a clock such as 50 MHz or 100 MHz, a clock divider or 1-second clock-enable must be added so that the timer receives a one-second timing tick.

The FSM itself does not need to change for this.

---

# 16. File Relationship

```text
                    ┌──────────────────────┐
                    │  sensor_decoder.v    │
                    └──────────┬───────────┘
                               │
                               ▼
                         traffic_condition
                               │
                               ▼
┌─────────────────────┐   ┌──────────────────┐
│emergency_controller │──►│  traffic_fsm.v   │
└─────────────────────┘   └───────┬──────────┘
                                  │
                            current_state
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
             traffic_timer.v          light_output_decode.v
                    │                           │
                    │ done signals              │
                    └──────────► FSM            ▼
                                         Traffic lights


priority_arbiter.v
        │
        └── grant
             (currently independent)
```

---

# 17. Design Philosophy

The project separates the controller into distinct hardware responsibilities:

### Combinational logic

- Sensor decoding
- Emergency decision logic
- Priority classification
- Light output decoding
- FSM next-state logic

### Sequential logic

- FSM state register
- Emergency pending storage
- Emergency direction storage
- Direction-change memory
- Emergency restoration storage
- Timer counters
- Previous-state tracking

This separation makes the design easier to simulate, debug, synthesize, and extend.

---

# 18. Main Design Features

- 8-state one-hot FSM
- Adaptive traffic selection from sensors
- Independent NS and EW traffic phases
- Dedicated right-turn phases
- Minimum and maximum green timing
- Yellow transition timing
- All-red safety interval
- Emergency vehicle detection
- Emergency direction selection
- Emergency buffering
- Emergency restoration of interrupted green time
- Safe default light output
- Modular RTL architecture
- Dedicated timing module
- Dedicated output decoder
- Simulation testbench
- FPGA-ready structural organization

---

# 19. Future Improvements

Potential future extensions include:

- Fully integrate `priority_arbiter` into the FSM decision path
- Complete pedestrian request handling
- Add pedestrian crossing timing
- Add pedestrian clearance/all-red timing
- Add a proper FPGA clock divider / one-second enable
- Add emergency timeout handling
- Support simultaneous emergency requests with a defined arbitration policy
- Add manual override behavior to the actual FSM
- Add fault detection for invalid sensor combinations
- Add formal assertions for mutually exclusive traffic lights
- Add comprehensive randomized simulation
- Map the controller to physical FPGA LEDs/switches
- Add a seven-segment/display debug interface

---

# 20. Safety Properties to Verify

During simulation, the following should always hold:

### No conflicting green lights

```text
NS_green && EW_green = 0
```

### Yellow must not coexist with its own green

```text
NS_green && NS_yellow = 0
EW_green && EW_yellow = 0
```

### All-red must stop both directions

```text
ALL_RED → NS_red = 1
           EW_red = 1
```

### Emergency direction must receive priority

```text
NS emergency → NS gets emergency green
EW emergency → EW gets emergency green
```

### State transitions must respect timing

For example:

```text
NS_GREEN
    ↓
minimum green completed
    ↓
NS_YELLOW
```

rather than immediately switching away from green.

---

# 21. Tools

The design is intended for Verilog HDL simulation and FPGA synthesis using tools such as:

- Xilinx Vivado
- Vivado Simulator
- GTKWave (if using an external simulator)
- FPGA development board for hardware testing

---

# 22. Project Summary

This project implements a modular adaptive traffic-light controller using Verilog HDL.

The **FSM is the decision-making core**, the **timer provides temporal constraints**, the **sensor decoder interprets traffic inputs**, the **emergency controller handles emergency requests**, and the **light decoder converts the resulting state into physical traffic-light outputs**.

The emergency subsystem additionally preserves the interrupted green-phase timing so that normal traffic operation can resume rather than simply restarting a complete green interval.

The current implementation intentionally keeps pedestrian handling and the priority arbiter outside the active FSM control path so that those features can be integrated later without compromising the existing state-machine behavior.

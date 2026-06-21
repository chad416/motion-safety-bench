# Industrial Motion & Safety Bench

Industrial Motion & Safety Bench is a TwinCAT 3 IEC 61131-3 Structured Text skeleton for a two-axis motion and safety-oriented demonstration cell. It models configuration, safety interlocks, alarms, mode control, homing, PLCopen motion, HMI data aggregation, trace logging, and simulation-first testing for a portfolio-grade industrial controls project.

## File List

| File | Description |
| --- | --- |
| `plc/Enumerations.st` | Enumerated types for modes, axis states, alarms, commands, homing, trace sources, and tests. |
| `plc/Structures.st` | Shared data structures for configuration, status, commands, alarms, traces, HMI data, and test results. |
| `plc/GVL_Constants.st` | Global constants for axis counts, alarm limits, trace buffers, and test capacity. |
| `plc/GVL_VirtualIO.st` | Global virtual I/O image used by simulation and TestHarness. |
| `plc/GVL_IO.st` | Physical I/O mapping with TwinCAT `AT %I/%Q` addresses. |
| `plc/ConfigPackage.st` | Configuration package FB for defaults, validation, and accessors. |
| `plc/SafetyManager.st` | Safety manager FB for E-stop, relay feedback, limit status, and safe-to-run state. |
| `plc/AlarmManager.st` | Alarm manager FB for condition evaluation, alarm buffers, acknowledgements, and resets. |
| `plc/ModeManager.st` | Mode manager FB for machine state transitions and mode permits. |
| `plc/AxisManager.st` | Axis manager FB for PLCopen power, move, jog, stop, reset, and axis status stubs. |
| `plc/HomingManager.st` | Homing manager FB with per-axis homing state machine skeleton. |
| `plc/CommandParser.st` | Command parser FB for HMI command validation and routing. |
| `plc/TraceLogger.st` | Trace logger FB with pending queue, ring buffer, and recent event outputs. |
| `plc/HMIModel.st` | HMI model FB that aggregates PLC status into `ST_HMIData`. |
| `plc/TestHarness.st` | Simulation-only test harness FB for command injection, virtual I/O, and result tracking. |
| `plc/MAIN.st` | Main PLC program wiring all FBs in the fixed cyclic call order. |
| `README.md` | Project overview, import order, library requirements, and usage notes. |

## TwinCAT 3 Import Order

1. `plc/Enumerations.st`
2. `plc/Structures.st`
3. `plc/GVL_Constants.st`
4. `plc/GVL_VirtualIO.st`
5. `plc/GVL_IO.st`
6. Import FB files in any order: `ConfigPackage.st`, `SafetyManager.st`, `AlarmManager.st`, `ModeManager.st`, `AxisManager.st`, `HomingManager.st`, `CommandParser.st`, `TraceLogger.st`, `HMIModel.st`, `TestHarness.st`
7. `plc/MAIN.st`

## Required TwinCAT Library

Add `Tc2_MC2` through TwinCAT > PLC > References. The project uses PLCopen motion function blocks such as `MC_Power`, `MC_Home`, `MC_MoveAbsolute`, `MC_MoveRelative`, `MC_Stop`, `MC_Reset`, and `MC_Jog`.

## Simulation

Simulation mode is enabled by default through `fbConfig.stMachineConfig.bSimulationMode := TRUE`. Keep simulation mode enabled when running the virtual I/O and test harness workflow.

## TestHarness

`bSimulationMode` must be `TRUE` before running tests. Start a single test with `fbTest.RunTest(nTestID)` or run the suite by setting `fbTest.bRunAllTests := TRUE`.

## Implementation Status

This is a skeleton. Method bodies intentionally contain TODO comments, and the detailed implementation follows in the next phase.

## Safety Note

This repository demonstrates a safety-oriented design approach only. It does not make any certified SIL or PL safety claim.

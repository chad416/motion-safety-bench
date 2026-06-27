# Factory Acceptance Test Protocol - Software Simulation

**Revision:** 2.1 - 2026-06-27
**Runtime:** TwinCAT 3.1, PLC ADS port 852
**Task:** 10 ms
**Current source harness:** 16 software FAT scenarios
**Retained evidence:** `MotionSafetyBench_Modular_FAT_Run02.csv/.json/.png` records the accepted 16/16 run.

## Purpose

Verify deterministic motion, safety interlock, alarm, and recovery behavior before hardware procurement. This protocol accepts software simulation only; it does not replace hardware SAT, stopping-time measurement, or certified safety validation.

## Preconditions

- TwinCAT runtime in RUN.
- PLC project generated from `plc/` and built with zero errors.
- Simulation mode enabled.
- Virtual E-stop, guard door, safety relay, STO, drive ready, encoder, network, and watchdog inputs healthy.
- Scope or ADS acquisition includes at least `MAIN.fActualPosition`, `MAIN.fActualVelocity`, mode, test counters, and pass/fail status.
- Test evidence filename is unique and repository validation records its checksum.

## Acceptance Matrix

| Test | Stimulus | Expected result | Key evidence |
|---|---|---|---|
| TR01 Startup and homing | Start suite, request INIT/HOMING, pulse home switches | Both axes homed; MANUAL-ready state | Mode, homed flags, home transition |
| TR02 Absolute move | Move Axis 1 to 100 mm | Position reaches 100.0 +/- 0.1 mm | Position ramp, standstill |
| TR03 Relative move | Move Axis 1 by +50 mm | Position advances by 50.0 +/- 0.1 mm | Initial/final position |
| TR04 Jog positive/negative | Hold jog positive, then jog negative | Axis moves both directions and stops on release | Position peak/return, velocity zero |
| TR05 Positive limit switch | Open positive NC limit during motion | Motion stops, FAULT observed, recovery returns to MANUAL | Limit status, mode, recovery |
| TR06 Negative limit switch | Open negative NC limit during motion | Motion stops, FAULT observed, recovery returns to MANUAL | Limit status, mode, recovery |
| TR07 E-stop during motion | Open E-stop chain during motion | Motion inhibited, FAULT observed, recovery returns to MANUAL | E-stop bit, velocity zero |
| TR08 Guard door during motion | Open guard-door input during motion | Motion inhibited, FAULT observed, recovery returns to MANUAL | Guard-door bit, mode |
| TR09 Drive fault | Inject Axis 1 drive fault | Axis error latched, FAULT observed, reset clears error | Axis error/status |
| TR10 Following error | Inject following-error flag | Following error detected, FAULT observed, reset clears error | Following error/status |
| TR11 Encoder feedback loss | Drop encoder feedback healthy bit | Feedback loss detected, FAULT observed, reset restores status | Feedback healthy/status |
| TR12 EtherCAT dropout | Drop network healthy bit | Motion inhibited, FAULT observed, recovery returns to MANUAL | Network healthy/status |
| TR13 Warm restart | Stop/restart command path | No stale motion command; axis remains standstill | Velocity, in-motion bit |
| TR14 Cold restart defaults | Restore virtual input defaults | All virtual safe defaults restored | Virtual I/O image |
| TR15 Watchdog timeout | Drop watchdog healthy bit | FAULT observed, reset restores healthy state | Watchdog status, mode |
| TR16 Invalid command/state transition | Request move while OFF | Command rejected; no motion occurs | Alarm count, velocity zero |

## Evidence Status

| Evidence set | Status | Scope |
|---|---|---|
| Run 01 recovery baseline | Retained | TwinCAT/ADS/Scope recovery path and motion plot |
| Run 02 modular FAT | Accepted evidence | 16/16 modular suite, build/download/restart verified |

## Run 02 Accepted Modular Summary

| Metric | Value |
|---|---:|
| Native/runtime build | 0 project errors |
| PLC target | ADS 852, 10 ms |
| Tests | 16 run / 16 passed / 0 failed |
| Captured ADS samples | 153 |
| FAT execution time | 19.772 s including deterministic PLC reset |
| Boot project | Generated, autostart enabled |
| Restart persistence | ADS returned to `Run` without download |

## Run 01 Measured Summary

| Metric | Value |
|---|---:|
| Samples per channel | 25,445 |
| Sample period | 10 ms |
| Position minimum | 0 mm |
| Position maximum | 215 mm |
| Velocity minimum | 0 mm/s |
| Velocity maximum | 200 mm/s |
| Non-zero velocity samples | 143 |
| ADS test result | 12 run / 12 passed / 0 failed |

## Procedure

1. Generate the portable PLC project with `tools/generate_twincat_project.ps1`.
2. Build the TwinCAT runtime solution; continue only after a zero-error build.
3. Activate/download the PLC to the simulation target.
4. Start ADS/Scope evidence acquisition.
5. Trigger the suite through `MAIN.bRunAutomatedTests` or `tools/run_modular_fat.ps1`.
6. For the current source baseline, confirm 16/16 pass and zero failures online.
7. Export uniquely named CSV/JSON/plot evidence to `simulation/test_runs/`.
8. Update SHA-256 records and run repository validation.
9. Review trends for position discontinuities, unexpected motion after inhibits, and recovery behavior.
10. Record deviations; do not overwrite failed evidence.

## Acceptance

Expanded software FAT is accepted: the modular application compiled, downloaded, ran 16/16 scenarios with zero failures, and retained ADS/plot/workbook evidence was regenerated with matching checksums.

## Evidence Limitation

Simulation results are engineering evidence for control logic only. They do not validate real stopping distance, certified safety hardware, EtherCAT device timing, servo tuning, cable faults, or mechanical load behavior. Hardware SAT remains mandatory.

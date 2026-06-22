# Factory Acceptance Test Protocol — Software Simulation

**Revision:** 2.0 — 2026-06-21
**Runtime:** TwinCAT 3.1 build 4024.75, PLC ADS port 852
**Task:** 10 ms
**Accepted modular evidence:** `MotionSafetyBench_Modular_FAT_Run02.csv/.json/.png`

**Recovery baseline:** `MotionSafetyBench_Simulation_Run01.csv/.png`

## Purpose

Verify deterministic software behavior before hardware procurement. This protocol accepts the software simulation only; it does not replace hardware SAT or certified safety validation.

## Preconditions

- TwinCAT runtime in RUN.
- PLC project downloaded with zero build errors.
- Simulation mode enabled.
- E-stop and safety-relay virtual inputs healthy.
- Scope acquisition contains `MAIN.fActualPosition` and `MAIN.fActualVelocity` at 10 ms.
- Test evidence filename is unique and repository validation records its checksum.

## Acceptance matrix

| Test | Stimulus | Expected result | Evidence signal | Run 02 modular | Run 01 baseline |
|---|---|---|---|---|---|
| TR01 Power-up/INIT | Start suite with safe defaults | INIT and axis enabled | mode/test counters | PASS | PASS |
| TR02 Homing | Simulate home reference | Homed at 0 mm; MANUAL-ready state | position returns to 0 | PASS | PASS |
| TR03 Absolute move | Target 100 mm | Position reaches 100 ±0.1 mm | position ramp | PASS | PASS |
| TR04 Relative move | +50 mm | Position reaches 150 ±0.1 mm | second position ramp | PASS | PASS |
| TR05 Manual jog | Hold positive jog | Position increases; velocity stops on release | jog segment | PASS | PASS |
| TR06 Soft limit | Request 999 mm | Command rejected; no move | position unchanged | PASS | PASS |
| TR07 E-stop in motion | Open E-stop during move | Velocity becomes zero; FAULT entered | interrupted motion | PASS | PASS |
| TR08 Fault reset | Restore chain, acknowledge/reset | RESET then INIT | mode/test status | PASS | PASS |
| TR09 Alarm acknowledge | Raise and acknowledge alarm | Alarm remains visible until cause clears | alarm/test status | PASS | PASS |
| TR10 Trace | Generate state events | Trace count > 0 | trace/test status | PASS | PASS |
| TR11 Warm restart | Clear active commands | No stale motion | velocity zero | PASS | PASS |
| TR12 Cold defaults | Restore safe virtual inputs | Safe virtual defaults restored | virtual I/O/test status | PASS | PASS |

## Run 02 accepted modular summary

| Metric | Value |
|---|---:|
| Native/runtime build | 0 project errors |
| PLC target | ADS 852, 10 ms |
| Tests | 12 run / 12 passed / 0 failed |
| Captured ADS samples | 46 |
| FAT execution time | 7.106 s including deterministic PLC reset |
| Boot project | Generated, autostart enabled |
| Restart persistence | ADS returned to `Run` without download |

## Run 01 measured summary

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

The long flat regions in the source CSV are recorder lead-in/lead-out time. Evidence-processing tools isolate the active-motion window for plots.

## Procedure

1. Generate/build the portable PLC project.
2. Activate and download only after a zero-error build.
3. Start the approved ADS/Scope evidence acquisition.
4. Trigger the test suite through `bRunAutomatedTests` or the verified runtime trigger.
5. Confirm 12/12 pass and zero failures online.
6. Stop acquisition and export uniquely named CSV/JSON evidence to `simulation/test_runs/`.
7. Run repository validation and evidence analysis.
8. Review the trend for position discontinuities, unexpected negative velocity and motion after E-stop.
9. Record deviations; do not overwrite failed evidence.

## Acceptance

Software FAT is accepted: the modular application compiled and downloaded, all twelve scenarios passed, the ADS capture contains actual motion, the boot project survived a runtime restart, and no critical software review finding remains open.

## Evidence limitation

Run 01 was captured from the deterministic runtime baseline used to establish TwinCAT/ADS/Scope operation. Run 02 independently verifies the generated modular architecture after native compile/download. Both are retained for auditability; neither result is silently substituted for the other, and neither replaces hardware SAT.

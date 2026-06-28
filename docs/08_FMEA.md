# Software and Bench FMEA

**Revision:** 1.1 — 2026-06-27
**Method:** Severity (S), occurrence (O), detection (D), each 1–10. `RPN = S × O × D`.

| Failure mode | Effect | Existing control | S | O | D | RPN | Required action |
|---|---|---|---:|---:|---:|---:|---|
| E-stop input stuck healthy | Stop demand not observed by PLC | Hardwired relay removes energy; discrepancy monitoring | 10 | 2 | 5 | 100 | Dual-channel certified circuit in Phase 2; proof test |
| Safety relay feedback absent | Motion permit inconsistent | 500 ms discrepancy timer and critical alarm | 9 | 3 | 2 | 54 | SAT disconnect test |
| Limit polarity reversed | False healthy/false trip | NC truth table and point-to-point SAT | 8 | 3 | 3 | 72 | Verify each contact before enabling drive |
| Soft limit configured incorrectly | Travel beyond intended software envelope | Config validation and command rejection | 8 | 3 | 3 | 72 | Independent mechanical-limit review |
| Stale execute bit repeats command | Uncommanded repeated motion | Rising-edge command parsing | 8 | 2 | 2 | 32 | Regression test repeated button hold |
| Mode transition bypass | Motion permitted in invalid mode | Central ModeManager permits | 8 | 2 | 3 | 48 | Transition-table test coverage |
| Homing switch never changes | Endless/incorrect homing | Step timeout, retry limit, fault transition | 7 | 3 | 2 | 42 | TR02 plus stuck-switch negative test |
| Axis/plant model diverges from hardware | Simulation passes, hardware fails | Separate SAT and tuning gate | 6 | 5 | 5 | 150 | Highest priority: repeat full SAT on selected drive/motor |
| Alarm can clear while cause active | Fault masked | Source condition evaluated every scan | 8 | 2 | 2 | 32 | Alarm lifecycle regression |
| HMI communication stale | Operator sees old status | PLC heartbeat and stale banner | 6 | 3 | 2 | 36 | Network interruption test |
| Trace buffer wraps unexpectedly | Evidence lost | Ring-buffer wrap flag and export process | 4 | 4 | 3 | 48 | Export before long run; retain checksum |
| Generated TwinCAT files drift from source | Wrong application built | Deterministic generator and repository validation | 7 | 3 | 2 | 42 | Regenerate and compare in quality gate |
| VBS/Hyper-V blocks runtime | No simulation/commissioning | Documented Beckhoff script and diagnostics | 4 | 4 | 1 | 16 | Preflight before scheduled FAT |
| Hardware sizing inadequate | Overload/poor control | Procurement hold until load data | 7 | 4 | 5 | 140 | Motor/drive sizing calculation before purchase |
| Guard-door input fails open | Nuisance stop / no motion | SafetyManager guard-door aggregation and alarm 1004 | 7 | 3 | 2 | 42 | Verify guard input polarity during SAT |
| Guard-door input stuck healthy | Motion may continue with guard open if hardwired safety also fails | Certified safety circuit required in Phase 2; PLC diagnostic only | 10 | 2 | 6 | 120 | Dual-channel safety device and validation |
| STO request not reflected to PLC | HMI may show stale permissive | STO healthy feedback and alarm 1005 | 9 | 2 | 4 | 72 | SAT trip test and drive inhibit verification |
| Encoder feedback loss | Position control invalid | Axis feedback healthy bit, alarm 2001, reset-required recovery | 8 | 3 | 2 | 48 | TR11 plus hardware feedback disconnect test |
| Following error exceeds limit | Servo cannot follow command | Following-error status, alarm 2001, fault/reset sequence | 8 | 3 | 2 | 48 | TR10 plus servo tuning review |
| EtherCAT/network dropout | Lost I/O or drive communication | Network healthy bit, alarm 1006, motion inhibit | 9 | 3 | 2 | 54 | TR12 plus cable pull SAT |
| PLC watchdog timeout | Runtime no longer deterministic | Watchdog healthy bit, alarm 1007, motion inhibit | 9 | 2 | 2 | 36 | TR15 plus cycle-time monitoring |
| Control power loss | PLC, I/O and drive control become unavailable; axis may coast unless the drive safety design removes torque safely | De-energize-to-safe outputs, external STO/safety relay, boot defaults with motion disabled | 10 | 3 | 3 | 90 | Phase 2 power-interruption SAT; verify safe stop category and restart inhibit |
| General sensor feedback loss or stuck state | Sequence may use stale or impossible process information | Plausibility checks, NC safety contacts, stuck-sensor timeout and explicit healthy bits | 8 | 3 | 3 | 72 | Inject open-circuit and stuck-high/stuck-low states; confirm alarm and motion inhibit |
| Limit switch fails to open or is bypassed | End-of-travel demand is not detected and mechanical overtravel is possible | Independent software limits, opposite-direction recovery only, mechanical end stop and Phase 2 safety review | 10 | 2 | 5 | 100 | SAT proof test each limit, wire-break detection and independent overtravel protection |
| Drive fault or drive-not-ready state | Torque or position control is unavailable; commanded motion cannot be trusted | Drive-ready permissive, drive-fault latch, alarm 2001, immediate motion inhibit and reset-required recovery | 9 | 3 | 2 | 54 | TR09 plus Phase 2 drive fault injection and diagnostic-code verification |

## Priority actions

1. Do not buy the motor/drive until mechanical load, inertia and duty cycle are known.
2. Validate certified safety architecture independently of this standard PLC project.
3. Execute every SAT point after hardware integration even when simulation FAT passes.
4. Store software version, TwinCAT build, parameter set and evidence checksum with each accepted run.

## Residual-risk statement

This FMEA supports engineering review and portfolio demonstration. It is not a machinery risk assessment under ISO 12100 and does not establish PL or SIL.

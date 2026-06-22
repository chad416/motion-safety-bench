# Software and Bench FMEA

**Revision:** 1.0 — 2026-06-21
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

## Priority actions

1. Do not buy the motor/drive until mechanical load, inertia and duty cycle are known.
2. Validate certified safety architecture independently of this standard PLC project.
3. Execute every SAT point after hardware integration even when simulation FAT passes.
4. Store software version, TwinCAT build, parameter set and evidence checksum with each accepted run.

## Residual-risk statement

This FMEA supports engineering review and portfolio demonstration. It is not a machinery risk assessment under ISO 12100 and does not establish PL or SIL.

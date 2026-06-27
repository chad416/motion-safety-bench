# Cause and Effect Matrix

**Revision:** 1.1 - 2026-06-27

Legend: **I** immediate software inhibit; **S** controlled stop request; **F** transition to FAULT; **A** alarm; **R** operator reset required.

| Cause | Drive enable | Active move | Mode | Alarm | Reset condition | FAT coverage |
|---|---|---|---|---|---|---|
| E-stop chain opens | I | S/I | F | 1001 Critical | Chain healthy + reset | TR07 |
| Safety relay feedback lost | I after discrepancy window | S/I | F | 1002 Critical | Feedback healthy + reset | Covered by safety input checks |
| Positive limit opens | I affected direction | S | F | 1003 Fault | Limit healthy + reset | TR05 |
| Negative limit opens | I affected direction | S | F | 1003 Fault | Limit healthy + reset | TR06 |
| Guard door opens | I | S/I | F | 1004 Critical | Guard closed + reset | TR08 |
| STO active / drive inhibit | I | S/I | F | 1005 Critical | STO healthy and drive-ready aggregate healthy + reset | TR09 plus SAT |
| EtherCAT/network dropout | I | S/I | F | 1006 Critical | Network healthy + reset | TR12 |
| Watchdog timeout | I | S/I | F | 1007 Critical | Watchdog healthy + reset | TR15 |
| Drive fault or not ready | I affected axis | S | F | 2001 Fault | Fault removed + RESET clears axis error | TR09 |
| Following error | I affected axis | S | F | 2001 Fault | Following error removed + RESET clears axis error | TR10 |
| Encoder feedback loss | I affected axis | S | F | 2001 Fault | Feedback healthy + RESET clears axis error | TR11 |
| Homing timeout/abort | No new motion | S | F | 3001 Fault | Cause removed + reset + new home command | TR01 negative checks in future |
| Absolute/relative target beyond soft limit | Unchanged | No command issued | Unchanged | 5001 Warning | Correct target + clear warning | Command validation path |
| Command in prohibited mode | Unchanged | No command issued | Unchanged | 5001 Warning | Select valid mode/command | TR16 |
| Invalid configuration | Inhibited | None | INIT/FAULT boundary | 5001 Warning/Fault policy | Correct configuration + reload defaults | Repository validation |
| HMI data stale | Unchanged | Existing PLC logic continues | Unchanged | HMI stale indication | Restore communications | HMI prototype |
| PLC/runtime stops | Output image safe by hardware design | Motion energy removed per drive/safety design | OFFLINE | External/HMI indication | Controlled restart and INIT checks | SAT |

## Priority Rules

1. Safety input loss overrides every command in the same PLC scan.
2. A reset command cannot override an active safety cause.
3. Stop/E-stop paths do not depend on HMI availability.
4. Acknowledgement changes alarm state only; it never changes an input.
5. Motion commands are edge-qualified, mode-validated and soft-limit checked before execution.
6. Axis drive, following-error and feedback faults latch until the source clears and RESET runs.

## Verification Mapping

| Matrix behavior | FAT test |
|---|---|
| Startup, INIT, homing and transition to MANUAL | TR01 |
| Absolute/relative move execution | TR02-TR03 |
| Bidirectional jog | TR04 |
| Limit-switch faults | TR05-TR06 |
| E-stop and guard-door inhibit | TR07-TR08 |
| Drive, following-error and feedback faults | TR09-TR11 |
| Network and watchdog faults | TR12, TR15 |
| Restart defaults | TR13-TR14 |
| Invalid command/state transition rejection | TR16 |

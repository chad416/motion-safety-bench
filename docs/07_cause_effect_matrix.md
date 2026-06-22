# Cause and Effect Matrix

**Revision:** 1.0 — 2026-06-21

Legend: **I** immediate software inhibit; **S** controlled stop request; **F** transition to FAULT; **A** alarm; **R** operator reset required.

| Cause | Drive enable | Active move | Mode | Alarm | Reset condition |
|---|---|---|---|---|---|
| E-stop chain opens | I | S/I | F | 1001 Critical | Chain healthy + acknowledge + reset |
| Safety relay feedback lost | I after discrepancy window | S/I | F | 1002 Critical | Feedback healthy + acknowledge + reset |
| Positive/negative limit opens | I affected direction | S | F | 1003 Fault | Limit healthy + acknowledge + reset |
| PLCopen axis error | I affected axis | S | F | 2001 Fault | Drive fault removed + axis reset |
| Homing timeout/abort | No new motion | S | F | 3001 Fault | Cause removed + acknowledge + new home command |
| Absolute target beyond soft limit | Unchanged | No command issued | Unchanged | 5001 Warning | Correct target + clear warning |
| Command in prohibited mode | Unchanged | No command issued | Unchanged | 5001 Warning | Select valid mode/command |
| Invalid configuration | Inhibited | None | INIT/FAULT boundary | 5001 Warning/Fault policy | Correct configuration + reload defaults |
| HMI data stale | Unchanged | Existing PLC logic continues | Unchanged | HMI banner | Restore communications |
| PLC/runtime stops | Output image safe by hardware design | Motion energy removed per drive/safety design | OFFLINE | External/HMI indication | Controlled restart and INIT checks |

## Priority rules

1. Safety input loss overrides every command in the same PLC scan.
2. A reset command cannot override an active safety cause.
3. Stop/E-stop paths do not depend on HMI availability.
4. Acknowledgement changes alarm state only; it never changes an input.
5. Motion commands are edge-qualified, mode-validated and soft-limit checked before execution.

## Verification mapping

| Matrix behavior | FAT test |
|---|---|
| Startup/INIT gating | TR01 |
| Homing completion | TR02 |
| Soft-limit rejection | TR06 |
| E-stop during motion | TR07 |
| Reset interlock | TR08 |
| Alarm acknowledgement | TR09 |
| Restart defaults | TR11–TR12 |

# Alarm List

**Revision:** 1.0 — 2026-06-21
**Safety status:** Safety-oriented concept only; no SIL/PL claim

| ID | Message | Severity | Trigger | Latching / clearing | Machine action | Operator response |
|---:|---|---|---|---|---|---|
| 1001 | Emergency-stop chain is open | Critical | E-stop healthy input `FALSE` | Latched; acknowledge after chain healthy | Inhibit/stop motion; FAULT | Inspect area, release E-stop, acknowledge, reset |
| 1002 | Safety relay feedback discrepancy | Critical | Healthy E-stop but relay feedback absent beyond 500 ms | Latched | Inhibit motion; FAULT | Inspect relay/feedback wiring; reset only when healthy |
| 1003 | Hardware limit switch activated | Fault | Any NC limit input opens | Latched | Stop affected/all axes; FAULT | Remove cause, inspect switch, acknowledge and reset |
| 2001 | Axis reported an error | Fault | PLCopen axis error output | Latched | Stop axis; FAULT | Record ErrorID, correct drive issue, reset axis |
| 3001 | Homing sequence failed | Fault | Homing abort, error or timeout | Latched | Stop homing; FAULT | Inspect home switch/path; acknowledge; retry |
| 5001 | Configuration or command validation warning | Warning | Invalid configuration or rejected command | Retained until reset | Reject command; no unsafe movement | Correct target/configuration; clear warning |

## Severity behavior

| Severity | Color | Latch | Mode impact |
|---|---|---|---|
| Info | Blue | No | None |
| Warning | Amber | As configured | Command may be rejected |
| Fault | Red | Yes | Enter FAULT; motion inhibited |
| Critical | Red flashing | Yes | Immediate motion inhibit; controlled/hardwired stop concept |

## Lifecycle

`INACTIVE → ACTIVE → ACKNOWLEDGED → INACTIVE`

Acknowledgement records operator awareness; it never removes the physical condition. Reset is accepted only when the source condition is no longer active and the safety chain is healthy.

## ID allocation

- 1000–1999: safety and interlocks
- 2000–2999: axis and drive
- 3000–3999: homing
- 4000–4999: communications
- 5000–5999: configuration/commands
- 6000–6999: HMI
- 8000–8999: automated tests

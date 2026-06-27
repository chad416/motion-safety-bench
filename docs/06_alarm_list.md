# Alarm List

**Revision:** 1.1 - 2026-06-27
**Safety status:** Safety-oriented concept only; no SIL/PL claim

| ID | Message | Severity | Trigger | Latching / clearing | Machine action | Operator response |
|---:|---|---|---|---|---|---|
| 1001 | Emergency-stop chain is open | Critical | E-stop healthy input is `FALSE` | Latched; clear only after chain healthy and reset | Inhibit/stop motion; FAULT | Inspect area, release E-stop, reset |
| 1002 | Safety relay feedback discrepancy | Critical | Healthy E-stop but relay feedback absent beyond discrepancy window | Latched | Inhibit motion; FAULT | Inspect relay/feedback wiring; reset only when healthy |
| 1003 | Hardware limit switch activated | Fault | Any NC limit input opens | Latched | Stop affected/all axes; FAULT | Remove cause, inspect switch, reset |
| 1004 | Guard door or safety gate is open | Critical | Guard-door healthy input is `FALSE` | Latched until guard closed and reset | Inhibit/stop motion; FAULT | Close guard, inspect interlock, reset |
| 1005 | STO active or drive inhibit requested | Critical | STO healthy input false or drive-ready aggregate unhealthy | Latched until inhibit clears and reset | Remove drive enable; FAULT | Verify STO chain/drive permissives, reset |
| 1006 | EtherCAT or network health lost | Critical | Network healthy bit false | Latched until communication healthy and reset | Inhibit motion; FAULT | Inspect EtherCAT/network path, reset |
| 1007 | PLC watchdog heartbeat timed out | Critical | Watchdog healthy bit false | Latched until watchdog healthy and reset | Inhibit motion; FAULT | Check PLC cycle/runtime load, reset |
| 2001 | Axis reported drive, feedback or following error | Fault | Drive fault, drive not ready, encoder feedback loss, or following-error injection | Latched until cause clears and RESET | Stop axis; FAULT | Record ErrorID/status, correct drive/feedback issue, reset |
| 3001 | Homing sequence failed | Fault | Homing abort, error or timeout | Latched | Stop homing; FAULT | Inspect home switch/path; reset; retry homing |
| 5001 | Configuration or command validation warning | Warning | Invalid configuration, prohibited command, soft-limit rejection | Retained until reset | Reject command; no unsafe movement | Correct target/configuration; clear warning |

## Severity Behavior

| Severity | Color | Latch | Mode impact |
|---|---|---|---|
| Info | Blue | No | None |
| Warning | Amber | As configured | Command may be rejected |
| Fault | Red | Yes | Enter FAULT; motion inhibited |
| Critical | Red flashing | Yes | Immediate software inhibit plus hardwired safety concept |

## Lifecycle

`INACTIVE -> ACTIVE -> ACKNOWLEDGED -> INACTIVE`

Acknowledgement or reset records operator awareness; it never removes the physical condition. Reset is accepted only when the source condition is no longer active and the safety chain is healthy.

## ID Allocation

- 1000-1999: safety and interlocks
- 2000-2999: axis and drive
- 3000-3999: homing
- 4000-4999: communications reserved for future detailed diagnostics
- 5000-5999: configuration/commands
- 6000-6999: HMI
- 8000-8999: automated tests

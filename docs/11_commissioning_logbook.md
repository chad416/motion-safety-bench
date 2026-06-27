# Commissioning Logbook

**Project:** Industrial Motion and Safety Bench  
**Revision:** 1.0 — 2026-06-21

## Software commissioning record

| Date/time | Activity | Result | Evidence / note |
|---|---|---|---|
| 2026-06-21 | Install/open TwinCAT XAE 4024.75 | PASS | Engineering environment operational |
| 2026-06-21 | Resolve VBS/Hyper-V runtime conflict | PASS | Beckhoff `DisableVirtualizationBasedSecurity.ps1`; restart completed |
| 2026-06-21 | Start real-time runtime | PASS | TcRTime and PLC runtime available |
| 2026-06-21 | Correct NC axis type | PASS | Standard encoder/drive mapping; no invalid Soft Drive object |
| 2026-06-21 | Build/download deterministic simulation | PASS | PLC port 852; zero build errors |
| 2026-06-21 | Execute 12 runtime scenarios | PASS | ADS: 12 run, 12 passed, 0 failed |
| 2026-06-21 | Configure Scope channels | PASS | Position and velocity at 10 ms |
| 2026-06-21 | Export Scope recording | PASS | `MotionSafetyBench_Simulation_Run01.csv` |
| 2026-06-21 | Verify exported evidence | PASS | 25,445 rows; position 0–215; velocity 0–200 |
| 2026-06-21 | Verify browser HMI prototype | PASS | Animated axis, E-stop and 12/12 UI regression |
| 2026-06-21 | Compile generated modular PLC | PASS | Native PLC solution and complete runtime solution: 0 project errors |
| 2026-06-21 | Activate modular runtime system | PASS | Local hardware-free NC/PLC system, ADS port 852 |
| 2026-06-21 | Download/start modular application | PASS | Forced download, ADS state `Run` |
| 2026-06-21 | Execute initial modular FAT rehearsal | PASS | 12 run, 12 passed, 0 failed; superseded by expanded 2026-06-27 acceptance |
| 2026-06-21 | Verify boot restart persistence | PASS | Port 852 returned directly to ADS `Run`; counters reset |
| 2026-06-27 | Rebuild/activate expanded modular runtime | PASS | TwinCAT XAE 4024.75; 0 errors, 0 warnings |
| 2026-06-27 | Execute expanded modular FAT Run 02 | PASS | ADS port 852: 16 run, 16 passed, 0 failed |
| 2026-06-27 | Regenerate evidence workbook and checksums | PASS | Workbook, CSV, JSON and plot hashes updated |

## Configuration baseline

| Item | Baseline |
|---|---|
| OS | Windows 11 x64 |
| TwinCAT | 3.1.4024.75 |
| PLC task | 10 ms |
| Active simulation ADS port | 852 |
| Source repository | `chad416/motion-safety-bench` |
| Safety status | Concept demonstration; not certified |

## Phase 2 hardware log template

| Date/time | Engineer | Device/tag | Action | Before | After | Result | Evidence |
|---|---|---|---|---|---|---|---|
| — | — | — | Hardware not yet procured | — | — | NOT EXECUTED | — |

## Deviation log

| ID | Description | Impact | Owner | Corrective action | Retest | Status |
|---|---|---|---|---|---|---|
| DEV-001 | Windows VBS initially prevented TwinCAT real-time start | Blocked simulation | Engineering | Use signed Beckhoff configuration script and restart | Runtime start | CLOSED |
| DEV-002 | Soft Drive object selected without TCom drive/encoder object | NC connection errors | Engineering | Restore Standard encoder/drive mapping for software model | Activate configuration | CLOSED |
| DEV-003 | Original imported `.st` files were content, not native PLC objects | Full modular code did not compile | Software | Deterministic `.TcDUT/.TcGVL/.TcPOU` generator | Native build gate | CLOSED |
| DEV-004 | Homing simulation omitted the second switch backoff/re-approach sequence | TR02 and dependent motion tests failed | Software | Complete per-axis switch sequence and initialize both virtual switches | Modular FAT | CLOSED |
| DEV-005 | Consecutive edge commands did not provide an R_TRIG re-arm scan | HOME/reset commands were ignored | Software | Insert explicit FALSE scan between separate command edges | Modular FAT | CLOSED |
| DEV-006 | Stale HOMING request survived fault reset | Controller left INIT immediately after reset | Software | Reset command establishes deterministic `MODE_INIT` request | Modular FAT | CLOSED |

## Change discipline

Every commissioning change records source revision, affected parameter/tag, reason, verifier and evidence. Failed attempts are retained when they explain a design correction; machine-specific routes and credentials are not committed publicly.

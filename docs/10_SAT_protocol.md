# Site Acceptance Test Protocol — Phase 2 Hardware

**Revision:** 1.0 — 2026-06-21
**Execution status:** NOT EXECUTED — hardware not procured

## Entry criteria

- Software FAT accepted and version tagged.
- Electrical drawings and point-to-point checks approved.
- Drive/motor sizing reviewed.
- Certified safety design approved by a competent person.
- Mechanical travel is clear; coupling may remain disconnected for initial checks.
- E-stop test plan and reset responsibilities agreed.

## SAT sequence

| SAT ID | Test | Method | Acceptance |
|---|---|---|---|
| SAT01 | Visual/electrical inspection | Verify PE, fusing, terminals, labels and separation | Matches drawings; no exposed conductors |
| SAT02 | 24/48 V power | Energize control then drive bus with motion inhibited | Voltages within component limits |
| SAT03 | EtherCAT topology | Compare scanned devices to approved list | All devices OP; identity/revision accepted |
| SAT04 | Digital input point check | Operate each switch/sensor | Correct tag and polarity only |
| SAT05 | Digital output point check | Force through commissioning mode | Correct device; safe state on stop |
| SAT06 | E-stop energy removal | Run at restricted speed, press each E-stop | Certified path removes motion energy; PLC reports fault |
| SAT07 | Relay discrepancy | Disconnect feedback under controlled conditions | Alarm 1002 and motion inhibit |
| SAT08 | Hardware limits | Approach both limits at reduced speed | Motion stops/inhibits hazardous direction |
| SAT09 | Drive enable/reset | Enable and reset with mechanics safe | No unexpected motion; errors recorded |
| SAT10 | Homing | Execute three cycles | Repeatability within mechanical requirement |
| SAT11 | Absolute/relative move | Execute representative targets | Position error and settling acceptable |
| SAT12 | Jog | Hold/release both directions | Motion only while held; correct direction |
| SAT13 | Power-cycle recovery | Cold and warm restart | No automatic motion; INIT required |
| SAT14 | HMI/ADS interruption | Disconnect engineering/HMI link | PLC control remains deterministic; stale banner shown |
| SAT15 | Full regression | Repeat software FAT scenarios applicable to hardware | No unexplained deviation |

## Required records

- Device list with serial/revision numbers.
- Drive firmware and parameter archive.
- I/O point-check sheet.
- E-stop stopping-time measurement where required.
- Homing repeatability and position-error measurements.
- Scope traces for normal move, limit stop and E-stop.
- Deviation log, corrective actions and retest evidence.

## Acceptance rule

Every critical SAT item must pass. Open cosmetic/documentation items may be conditionally accepted with owner and deadline. Safety, unexpected motion, wiring and drive faults are never conditionally accepted.

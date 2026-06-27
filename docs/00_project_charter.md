# Project Charter — Industrial Motion and Safety Bench

**Revision:** 1.0
**Date:** 2026-06-21
**Software baseline target:** 2026-07-15
**Platform:** TwinCAT 3.1 build 4024.75, IEC 61131-3 Structured Text

## Mission

Build a portfolio-grade industrial motion-control reference system that demonstrates requirements engineering, modular PLC design, virtual commissioning, safety-oriented interlocking, alarm handling, HMI design, automated FAT testing, trace evidence, and a credible path to Beckhoff EtherCAT hardware.

Simulation proves behavior before procurement. Hardware validates the design; it is not used to discover basic logic defects.

## Scope

- One primary virtual linear axis and provision for a second axis.
- Seven machine modes: OFF, INIT, HOMING, MANUAL, AUTO, FAULT, RESET.
- PLCopen-compatible motion abstraction with deterministic software-plant mode.
- E-stop, safety-relay feedback, limit-switch and motion-permit logic.
- Alarm lifecycle, trace/event buffer and HMI-facing data model.
- Sixteen repeatable simulation FAT scenarios in the current source harness.
- TwinCAT Scope evidence and CSV export.
- Browser-based HMI prototype using the same public status/command model.
- URS, FDS, SDS, I/O, network, alarm, cause/effect, FMEA, FAT/SAT, commissioning checklist and final report.
- Portable TwinCAT native project generation from reviewed ST source.

## Non-scope

- A certified safety function, SIL/PL calculation or safety PLC application.
- Final machine guarding, CE conformity assessment or production release.
- Real servo tuning, EMC validation or electrical-panel certification.
- Claims of hardware commissioning before physical hardware exists.

## Assumptions

- TwinCAT task period is 10 ms.
- Simulation uses a deterministic software plant and virtual I/O.
- NC limits and safety inputs use fail-safe semantics: healthy NC circuits are `TRUE`.
- Phase 2 hardware will use 24 VDC control I/O and a 48 VDC motion subsystem.
- The same public PLC interfaces are used by the HMI and TestHarness.

## Software-first work breakdown

| ID | Work package | Exit criterion |
|---|---|---|
| WP1 | Requirements and functional design | URS/FDS approved and traceable |
| WP2 | Software architecture | SDS, types, interfaces and cyclic order defined |
| WP3 | PLC implementation | No TODO stubs; portable native TwinCAT objects generated |
| WP4 | Virtual commissioning | Runtime starts, Scope channels record motion |
| WP5 | Automated FAT | 16/16 scenarios pass with retained evidence |
| WP6 | HMI | Operator prototype supports status, motion, tests and E-stop demonstration |
| WP7 | Engineering records | Alarm, cause/effect, FMEA, FAT/SAT and network documents complete |
| WP8 | Portfolio package | README, case study and demonstration scripts reviewed |
| WP9 | Hardware readiness | BOM, wiring plan and commissioning gates complete |

## Deliverables

1. Reviewed ST source and generated TwinCAT native project.
2. TwinCAT configuration and repeatable build/generation tools.
3. Verified Scope CSV and derived evidence plots.
4. Sixteen-scenario FAT report and retained evidence.
5. HMI prototype and tag/screen specification.
6. Engineering document set under `docs/`, including standalone commissioning checklist and final engineering report.
7. Phase 2 BOM, wiring plan and procurement risk register.
8. Portfolio case study and demonstration scripts.

## Risks and controls

| Risk | Impact | Control |
|---|---|---|
| Windows VBS blocks TwinCAT real-time | Runtime unavailable | Beckhoff VBS configuration script; retain recovery procedure |
| Simulation diverges from hardware | False confidence | Keep plant model separate; repeat SAT on hardware |
| NC/limit polarity error | Unsafe behavior | Fail-safe truth table, cause/effect review and SAT point checks |
| Generated project drifts from ST | Non-reproducible build | Deterministic generator; CI/static validation |
| Evidence is overwritten | Audit gap | Immutable run filenames and checksums |
| Portfolio overstates certification | Credibility/safety risk | Explicit non-certified disclaimer in every safety document |

## Milestones

| Date | Milestone |
|---|---|
| 2026-06-21 | TwinCAT runtime operational; first Scope CSV captured |
| 2026-06-24 | Modular PLC source and native project generation complete |
| 2026-06-28 | HMI prototype and automated evidence pipeline complete |
| 2026-07-03 | FAT/FMEA/cause-effect review complete |
| 2026-07-08 | Portfolio walkthrough and repository QA complete |
| 2026-07-15 | Software baseline tagged; Phase 2 hardware gate decision |

## Current gate status - 2026-06-27

- WP1–WP8 software/portfolio scope: complete and validated.
- Native PLC and complete runtime system: zero project build errors.
- Modular runtime: activated and running on ADS port 852.
- Modular FAT Run 02: 16/16 passed, zero failed.
- Boot-project autostart: verified through runtime restart.
- WP9 documentation/readiness: complete; procurement remains held for motor/load sizing and certified safety review.
- Hardware SAT: not executed because Phase 2 hardware has not been procured.

## Simulation gate before hardware

Hardware procurement is not authorized until all conditions are true:

- PLC project builds without errors.
- Safety loss overrides motion in the same scan.
- Soft limits reject invalid commands.
- Fault reset cannot bypass an unhealthy safety chain.
- Homing timeout and abort paths are tested.
- All 16 FAT scenarios pass.
- Scope data and an evidence summary are committed.
- HMI commands pass through the same command validator used by tests.

## Decisions deferred to Phase 2

Motor sizing, exact EL7211 variant, gearbox ratio, brake resistor, cable lengths, enclosure dimensions, certified safety relay/PLC choice and final sensor part numbers remain provisional until mechanical loads and budget are confirmed.

## Governance

Source code, generated artifacts and evidence are reviewed as separate layers. A successful simulation is evidence for software behavior only. Hardware acceptance requires the SAT protocol and signed commissioning records.

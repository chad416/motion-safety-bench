# Commissioning Checklist - Software Baseline

**Project:** Industrial Motion and Safety Bench  
**Revision:** 1.0 - 2026-06-27  
**Scope:** Software-first commissioning only. Phase 2 hardware checks are listed as gated items and are not executed.

## Commissioning Boundary

This checklist closes the non-hardware commissioning package for the TwinCAT runtime simulation. It verifies that the reviewed PLC source, generated TwinCAT project, runtime configuration, evidence files, HMI prototype, and engineering documents are aligned to the accepted 16-scenario software FAT.

It does not claim completion of real wiring, servo tuning, certified safety validation, stopping-time measurement, or mechanical commissioning.

## Entry Criteria

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-ENT-01 | Reviewed ST source exists under `plc/` | PASS | 16 Structured Text source files |
| SW-ENT-02 | Native TwinCAT objects generated from source | PASS | `twincat/RuntimeSimulation/` |
| SW-ENT-03 | Runtime solution targets local ADS port 852 | PASS | `twincat/MotionSafetyBenchRuntime.sln` |
| SW-ENT-04 | Simulation mode selected for hardware-free testing | PASS | `FB_ConfigPackage`, virtual I/O defaults |
| SW-ENT-05 | Safety disclaimer retained | PASS | README and safety documents |

## PLC And Runtime Checklist

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-PLC-01 | TwinCAT XAE rebuild completes with zero errors and zero warnings | PASS | Manual XAE rebuild, 2026-06-27 |
| SW-PLC-02 | Runtime configuration activates and restarts TwinCAT cleanly | PASS | XAE activation log, 2026-06-27 |
| SW-PLC-03 | PLC downloads/logs in to ADS port 852 | PASS | Run 02 JSON `targetPort = 852` |
| SW-PLC-04 | PLC reaches ADS `Run` state | PASS | Run 02 JSON `adsState = Run` |
| SW-PLC-05 | Boot/autostart path verified after runtime restart | PASS | FAT protocol and logbook |
| SW-PLC-06 | Generated PLC project contains expected native objects | PASS | Validator: 26 DUT, 3 GVL, 11 POU |

## Functional Checklist

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-FNC-01 | Mode manager covers OFF, INIT, HOMING, MANUAL, AUTO, FAULT, RESET | PASS | `plc/ModeManager.st` |
| SW-FNC-02 | Command parser validates move, jog, home, reset, acknowledge and velocity commands | PASS | `plc/CommandParser.st` |
| SW-FNC-03 | Axis manager supports simulation plant and PLCopen hardware path | PASS | `plc/AxisManager.st` |
| SW-FNC-04 | Homing manager handles timeout and dual-axis ready state | PASS | `plc/HomingManager.st` |
| SW-FNC-05 | Trace logger and HMI model expose operator-facing status | PASS | `plc/TraceLogger.st`, `plc/HMIModel.st` |
| SW-FNC-06 | Test harness uses public command and virtual I/O paths | PASS | `plc/TestHarness.st` |

## Safety-Oriented Software Checklist

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-SAF-01 | E-stop loss inhibits motion and enters FAULT | PASS | FAT TR07 |
| SW-SAF-02 | Guard-door loss inhibits motion and enters FAULT | PASS | FAT TR08 |
| SW-SAF-03 | STO/drive inhibit is modeled in safety status | PASS | Safety manager and I/O list |
| SW-SAF-04 | Positive and negative limit loss stop motion and recover through reset | PASS | FAT TR05, TR06 |
| SW-SAF-05 | Drive fault, following error and encoder loss latch fault state | PASS | FAT TR09, TR10, TR11 |
| SW-SAF-06 | EtherCAT/network and watchdog loss inhibit motion | PASS | FAT TR12, TR15 |
| SW-SAF-07 | Invalid move command while OFF is rejected | PASS | FAT TR16 |

## Evidence Checklist

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-EVD-01 | Accepted modular FAT CSV retained | PASS | `simulation/test_runs/MotionSafetyBench_Modular_FAT_Run02.csv` |
| SW-EVD-02 | Accepted modular FAT JSON retained | PASS | `simulation/test_runs/MotionSafetyBench_Modular_FAT_Run02.json` |
| SW-EVD-03 | Accepted modular FAT plot retained | PASS | `simulation/test_runs/MotionSafetyBench_Modular_FAT_Run02.png` |
| SW-EVD-04 | Evidence workbook regenerated | PASS | `outputs/motion-safety-bench/MotionSafetyBench_Simulation_Evidence.xlsx` |
| SW-EVD-05 | SHA-256 records updated and verified | PASS | `simulation/test_runs/SHA256SUMS.txt` |
| SW-EVD-06 | Repository validator passes | PASS | `tools/validate_project.ps1` |

## Documentation Checklist

| ID | Check | Status | Evidence |
|---|---|---|---|
| SW-DOC-01 | URS/FDS/SDS baseline complete | PASS | `docs/01_URS.md`, `docs/02_FDS.md`, `docs/03_SDS.md` |
| SW-DOC-02 | I/O, network, alarm and cause/effect documents complete | PASS | `docs/04_IO_list.md` through `docs/07_cause_effect_matrix.md` |
| SW-DOC-03 | FMEA updated for expanded fault cases | PASS | `docs/08_FMEA.md` |
| SW-DOC-04 | FAT protocol records accepted 16/16 run | PASS | `docs/09_FAT_protocol.md` |
| SW-DOC-05 | SAT protocol preserves hardware-only acceptance boundary | PASS | `docs/10_SAT_protocol.md` |
| SW-DOC-06 | Commissioning logbook records software commissioning history | PASS | `docs/11_commissioning_logbook.md` |
| SW-DOC-07 | Final engineering report issued | PASS | `docs/13_final_engineering_report.md` |

## Phase 2 Hardware Gate

| ID | Check | Status | Required Before Execution |
|---|---|---|---|
| HW-GATE-01 | Motor/load sizing finalized | NOT EXECUTED | Mechanical load, inertia and duty-cycle data |
| HW-GATE-02 | Beckhoff EtherCAT hardware procured | NOT EXECUTED | Approved BOM and budget |
| HW-GATE-03 | Electrical drawings released | NOT EXECUTED | Terminal plan, fusing, PE and cable schedule |
| HW-GATE-04 | Certified safety design reviewed | NOT EXECUTED | Safety relay/PLC selection and risk assessment |
| HW-GATE-05 | Real I/O point check completed | NOT EXECUTED | Wired panel and SAT point-check sheet |
| HW-GATE-06 | Stopping-time measurement completed | NOT EXECUTED | Physical drive, mechanics and measurement equipment |
| HW-GATE-07 | Servo tuning and homing repeatability proven | NOT EXECUTED | Real motor/load system |

## Release Decision

Software commissioning is complete for the hardware-free TwinCAT baseline. The project is ready for source control release as a software FAT package and ready to enter Phase 2 planning. Hardware commissioning remains blocked until the Phase 2 gate items above are satisfied.

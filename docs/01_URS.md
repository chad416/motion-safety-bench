# User Requirements Specification (URS)
## Industrial Motion and Safety Bench

**Document:** docs/01_URS.md  
**Revision:** 1.0  
**Date:** 2026-06-20  
**Platform:** TwinCAT 3 / EtherCAT / IEC 61131-3 Structured Text  
**Status:** APPROVED — Baseline for software development and simulation  
**Safety note:** This system implements safety-oriented design. No certified SIL or PL function is claimed.

---

## 1. Purpose and Scope

### 1.1 Purpose
This URS defines **what** the Industrial Motion and Safety Bench must do. It is the requirements baseline for software development (Prompt 4–5), simulation validation (Prompt 6), and acceptance testing (Prompt 8). The FDS (docs/02_FDS.md) defines **how** the system behaves.

### 1.2 System Description
A 1–2 axis motion control bench demonstrating industrial-grade PLC/ST logic, PLCopen motion control, EtherCAT communication, safety-oriented design, HMI operation, alarm management, trace logging, and commissioning discipline. Phase 1 uses TwinCAT 3 virtual axes in simulation. Phase 2 maps the same software to real Beckhoff EK1100 + EL7211 + AM31xx/AM81xx hardware.

### 1.3 Intended Users

| User | Mode of interaction |
|------|-------------------|
| Operator | HMI screens — mode selection, jog, auto start/stop, alarm acknowledge |
| Commissioning engineer | Configuration screen, homing calibration, trace export |
| Portfolio reviewer | Public GitHub repository — code, docs, simulation screenshots, FAT report |

### 1.4 Axes Configuration

| Axis | Role | Status |
|------|------|--------|
| Axis 1 | Primary — all requirements apply | Required (minimum viable) |
| Axis 2 | Optional second axis — same requirements apply | Added after Axis 1 Simulation FAT passes |

Requirements tagged `[AX1]` apply to Axis 1 only. Requirements tagged `[AX1,AX2]` apply to both axes.

---

## 2. Operating Mode Requirements [URS-MOD]

**URS-MOD-001** `[AX1,AX2]`  
The system SHALL implement exactly seven operating modes: **OFF, INIT, HOMING, MANUAL, AUTO, FAULT, RESET**.

**URS-MOD-002** `[AX1,AX2]`  
At any time, the system SHALL be in exactly one operating mode. Parallel modes are not permitted.

**URS-MOD-003** `[AX1,AX2]`  
The current mode SHALL be visible on all HMI screens at all times as a persistent status element.

**URS-MOD-004** `[AX1,AX2]`  
Mode transitions SHALL only occur as defined in the FDS state transition table. Undefined transitions SHALL be blocked by ModeManager logic.

**URS-MOD-005** `[AX1,AX2]`  
Any active CRITICAL alarm SHALL prevent transition to HOMING, MANUAL, or AUTO until the fault is cleared via a complete RESET cycle.

**URS-MOD-006** `[AX1,AX2]`  
A completed homing sequence (HomeDone = TRUE) SHALL be a mandatory precondition for entering AUTO mode.

**URS-MOD-007** `[AX1,AX2]`  
MANUAL mode SHALL be accessible from HOMING (on successful completion) and from AUTO (on operator request) without requiring a new homing cycle, provided no CRITICAL fault has occurred and HomeDone remains TRUE.

---

## 3. Motion Requirements [URS-MOT]

**URS-MOT-001** `[AX1,AX2]`  
The system SHALL control each axis using PLCopen-compliant motion function blocks: MC_Power, MC_Home, MC_MoveAbsolute, MC_MoveRelative, MC_Jog, MC_Halt, MC_Stop, MC_Reset.

**URS-MOT-002** `[AX1,AX2]`  
All motion function blocks SHALL reference axes by symbolic name only. No hardcoded EtherCAT physical addresses SHALL appear in any ST source file.

**URS-MOT-003 — Homing** `[AX1,AX2]`  
The system SHALL execute a defined homing sequence in HOMING mode:
- Move toward home switch at configurable homing velocity
- Detect home switch activation (DI_HomeSwitch_Ax1)
- Return axis to configured home offset position (default: 0.0 mm)
- Set HomeDone[axis] = TRUE on successful completion
- Generate CRITICAL alarm and transition to FAULT if home switch not found within HomingTimeout

**URS-MOT-004 — Absolute Move** `[AX1,AX2]`  
In MANUAL or AUTO mode, the system SHALL execute absolute position moves via MC_MoveAbsolute with configurable target position, velocity, acceleration, and deceleration parameters.

**URS-MOT-005 — Relative Move** `[AX1,AX2]`  
In MANUAL or AUTO mode, the system SHALL execute relative position moves via MC_MoveRelative with configurable distance, velocity, acceleration, and deceleration parameters.

**URS-MOT-006 — Manual Jog** `[AX1,AX2]`  
In MANUAL mode, the system SHALL support continuous jog in both positive and negative directions via MC_Jog while an operator jog command is held active. Motion SHALL stop when the command is released.

**URS-MOT-007 — Software Position Limits** `[AX1,AX2]`  
The system SHALL enforce configurable software position limits (SoftLimitPos, SoftLimitNeg) on each axis. Any move command that would result in a position outside these limits SHALL be rejected with a WARNING alarm before motion begins. Soft limits SHALL also be monitored continuously during motion.

**URS-MOT-008 — Velocity and Acceleration Limits** `[AX1,AX2]`  
All move commands SHALL be bounded by configurable maximum velocity, acceleration, and deceleration parameters per axis stored in ConfigPackage.

**URS-MOT-009 — Position Hold** `[AX1,AX2]`  
When motion stops in MANUAL or AUTO mode without a fault condition, the axis SHALL maintain the last commanded position (servo hold active) until a new move command is issued or the system transitions to FAULT.

---

## 4. Safety Requirements [URS-SAF]

**URS-SAF-001 — E-Stop Monitoring** `[AX1,AX2]`  
The system SHALL monitor DI_EStop (NC contact). When DI_EStop is de-asserted (contact opened), the system SHALL within one PLC scan:
- Call MC_Stop on all active axes
- De-assert all drive enables
- Transition to FAULT mode
- Latch the FAULT condition until operator reset

**URS-SAF-002 — Safety Relay Monitoring** `[AX1,AX2]`  
The system SHALL monitor DI_SafetyRelay_OK (safety relay output feedback). Loss of this signal SHALL be treated identically to an E-stop condition (URS-SAF-001).

**URS-SAF-003 — Hardware Limit Monitoring** `[AX1,AX2]`  
The system SHALL monitor DI_LimitPos_Ax1 and DI_LimitNeg_Ax1. Activation of either limit switch during motion SHALL immediately halt axis motion and transition to FAULT mode with a CRITICAL alarm.

**URS-SAF-004 — Drive Enable Interlock** `[AX1,AX2]`  
The system SHALL only assert DO_DriveEnable_Ax1 when ALL of the following conditions are simultaneously true:
- System mode is HOMING, MANUAL, or AUTO
- DI_EStop = TRUE (chain healthy)
- DI_SafetyRelay_OK = TRUE
- No CRITICAL drive fault active

**URS-SAF-005 — Safe Stop on Fault** `[AX1,AX2]`  
On transition to FAULT mode, drive enable SHALL be de-asserted within one PLC scan cycle. This is a safety-oriented design measure. No certified SIL/PL function is claimed.

**URS-SAF-006 — Brake Control** `[AX1,AX2]`  
DO_BrakeRelease_Ax1 SHALL only be asserted when drive enable is TRUE and a motion command is active. The brake SHALL be applied before drive enable is removed on a controlled stop.

**URS-SAF-007 — Application Watchdog** `[AX1,AX2]`  
The PLC application SHALL implement a watchdog mechanism. If the PLC scan cycle overruns the configured watchdog tolerance, the system SHALL transition to FAULT with ALM-WATCHDOG-001.

---

## 5. Alarm Requirements [URS-ALM]

**URS-ALM-001**  
The system SHALL implement a structured alarm system with three severity levels: CRITICAL, WARNING, INFO.

**URS-ALM-002**  
Every alarm SHALL have a defined: Alarm ID, description, severity, cause condition, required operator action, and reset rule.

**URS-ALM-003**  
All alarms SHALL be timestamped with PLC system time at the moment of activation.

**URS-ALM-004**  
CRITICAL alarms SHALL require explicit operator acknowledgement before the system can enter RESET mode.

**URS-ALM-005**  
WARNING alarms SHALL be visible on the HMI Alarms screen but SHALL NOT independently prevent motion continuation unless they escalate to CRITICAL.

**URS-ALM-006**  
INFO alarms SHALL be logged and auto-clear after a configurable timeout (default 10 s). No operator action is required.

**URS-ALM-007**  
AlarmManager SHALL maintain a minimum 100-entry alarm history log containing: timestamp, alarm ID, severity, system mode at activation, and acknowledge status.

**URS-ALM-008**  
The active alarm list and alarm history SHALL both be visible on the HMI Alarms screen.

---

## 6. HMI Requirements [URS-HMI]

**URS-HMI-001**  
The system SHALL provide exactly seven HMI screens: Overview, Axis Status, Manual/Jog, Auto Sequence, Alarms, Diagnostics/Trace, Configuration.

**URS-HMI-002 — Overview**  
SHALL display: current mode, Axis 1 position and velocity, active alarm count, E-stop chain status, PLC cycle time, and navigation buttons to all other screens.

**URS-HMI-003 — Manual/Jog**  
SHALL provide: jog positive (hold) button, jog negative (hold) button, target position input field, relative distance input field, move execute button, stop button, velocity setpoint input, and current position display.

**URS-HMI-004 — Auto Sequence**  
SHALL display: current sequence step name, step number, cycle count, max cycles configured, sequence state. SHALL provide: Start, Stop/Pause, Reset controls.

**URS-HMI-005 — Alarms**  
SHALL display active alarm list (ID, description, severity, timestamp, acknowledge button) and alarm history (minimum 100 entries, scrollable). SHALL provide Acknowledge Selected and Acknowledge All buttons.

**URS-HMI-006 — Diagnostics/Trace**  
SHALL display last 50 trace log entries in real time (timestamp, mode, Ax1 position, Ax1 velocity, alarm count). SHALL provide export function for trace buffer to CSV.

**URS-HMI-007 — Configuration**  
SHALL allow editing of: soft limits, velocity/acceleration limits, homing parameters, auto sequence positions and dwell times, watchdog tolerance. SHALL be access-controlled.

**URS-HMI-008 — Persistent Status**  
All seven screens SHALL display current mode, E-stop status, and active alarm count as persistent header elements.

---

## 7. I/O Requirements [URS-IO]

**URS-IO-001**  
All I/O SHALL be referenced by symbolic tag names in ST code. Physical EtherCAT terminal channel addresses SHALL only appear in the hardware configuration (TwinCAT I/O tree). Zero physical addresses SHALL appear in .st source files.

**URS-IO-002 — Minimum I/O count per axis**  
- Digital inputs: 2 hardware limit switches, 1 home switch, 1 drive ready signal
- Digital inputs (system): 1 E-stop chain input, 1 safety relay feedback
- Digital outputs: 1 drive enable, 1 brake release, 1 axis status beacon

**URS-IO-003 — Simulation I/O**  
In simulation mode (ConfigPackage.bSimulationMode = TRUE), all physical I/O SHALL be replaced by a software virtual I/O structure (stVirtualIO). No modification to motion or safety logic SHALL be required to switch between simulation and hardware modes.

**URS-IO-004**  
The complete I/O signal list with tag names, signal types, NC/NO designation, simulation defaults, and Phase 2 terminal assignments is maintained in docs/04_IO_list.md.

---

## 8. Network Requirements [URS-NET]

**URS-NET-001**  
The fieldbus SHALL be EtherCAT. The EtherCAT master SHALL be TwinCAT 3 NC PTP running on the development PC (Windows 10/11).

**URS-NET-002**  
In simulation, no physical EtherCAT devices are required. TwinCAT virtual axes SHALL provide position, velocity, and state feedback equivalent to real EtherCAT servo terminals.

**URS-NET-003**  
In hardware phase, the EtherCAT device tree SHALL include: EK1100 EtherCAT coupler, EL7211-0010 servo terminal per axis, EL1008 8-channel digital input terminal, EL2008 8-channel digital output terminal, EL9011 bus end terminal.

**URS-NET-004**  
EtherCAT cycle time SHALL be configurable; default 1 ms for both simulation and hardware phases.

**URS-NET-005**  
Loss of EtherCAT communication (any slave not in OP state) SHALL trigger ALM-ETHERCAT-001 (CRITICAL) and transition to FAULT mode.

---

## 9. Trace Logging Requirements [URS-TRC]

**URS-TRC-001**  
TraceLogger SHALL record per scan: timestamp (PLC system time), current mode, Ax1 actual position, Ax1 actual velocity, active alarm count, I/O state word (packed digital inputs/outputs).

**URS-TRC-002**  
The trace buffer SHALL be a circular buffer with minimum 1,000 entries. Oldest entries overwritten when full.

**URS-TRC-003**  
All mode transitions SHALL be recorded as discrete trace events in addition to the periodic scan log.

**URS-TRC-004**  
Trace data SHALL be exportable to CSV format from the Diagnostics/Trace HMI screen.

**URS-TRC-005**  
The last 50 trace entries SHALL be visible in real time on the Diagnostics/Trace screen.

---

## 10. Acceptance Criteria [URS-ACC]

| ID | Criterion | Procedure | Pass threshold |
|----|-----------|-----------|---------------|
| ACC-001 | All 7 modes reachable | Navigate full mode sequence in simulation | All 7 modes entered and exited per state machine |
| ACC-002 | Homing completes successfully | Execute homing with virtual axis | HomeDone=TRUE, position=0.0 mm, no alarms |
| ACC-003 | Homing repeatability | Execute homing 3× in simulation | Position at home identical across all 3 runs |
| ACC-004 | Absolute move — 3 positions | Command 100.0, 50.0, −5.0 mm in simulation | Final position matches command (virtual axis tolerance) |
| ACC-005 | Relative move | Command +10 mm from known position | Delta position matches command |
| ACC-006 | E-stop during motion | Assert DI_EStop=FALSE while axis moving | Axis stops, mode=FAULT within 1 scan |
| ACC-007 | Full Fault/Reset cycle | Trigger CRITICAL alarm, acknowledge, Reset | Clean FAULT→RESET→INIT without stale alarms |
| ACC-008 | Soft limit rejection | Command move beyond SoftLimitPos | Command rejected, ALM-SOFTLIMIT-001 raised |
| ACC-009 | Alarm logging | Trigger 5 different alarms | All 5 appear in active list and history with timestamp |
| ACC-010 | Trace coverage | Run system for 5 minutes | ≥300 trace entries with correct timestamps |
| ACC-011 | Trace export | Press export on Diagnostics screen | Valid CSV file with all defined fields |
| ACC-012 | HMI completeness | Navigate all 7 screens | All screens display correct live data |
| ACC-013 | No hardcoded addresses | Grep all .st files for physical I/O patterns | Zero matches found |
| ACC-014 | Module count | Count files in plc/ | Exactly 10 separate .st files |
| ACC-015 | Safety language compliance | Review all docs/ files | Zero certified SIL/PL claims found anywhere |

---

## 11. Document Control

| Rev | Date | Author | Change |
|-----|------|--------|--------|
| 1.0 | 2026-06-20 | Project team | Initial issue — baseline for software development |

---
*Paired with: docs/02_FDS.md (behavior), docs/03_SDS.md (software design), docs/04_IO_list.md (I/O detail)*

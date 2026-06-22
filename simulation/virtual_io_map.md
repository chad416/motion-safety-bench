# Virtual I/O Map
## Industrial Motion and Safety Bench — Simulation Mode

**Document:** simulation/virtual_io_map.md  
**Revision:** 1.0  
**Date:** 2026-06-21  
**Applies when:** ConfigPackage.bSimulationMode = TRUE  
**Access path:** GVL_VirtualIO.stVirtualIO.[field]

---

## 1. How Virtual I/O Works

When `bSimulationMode = TRUE`, SafetyManager.ReadInputs() reads from `GVL_VirtualIO.stVirtualIO` instead of `GVL_IO`. All other modules are unaware of the switch. Zero code changes required.

To manipulate signals during simulation:
- **Manual:** TwinCAT Watch Window → expand `GVL_VirtualIO.stVirtualIO` → double-click value to edit
- **Automated:** TestHarness.InjectVirtualIO() method sets these fields programmatically

---

## 2. Virtual Digital Inputs (simulated sensors)

| ST field | Corresponds to | NC/NO | Default | Set to simulate |
|---------|---------------|-------|---------|----------------|
| `stVirtualIO.bEStop` | DI_EStop — E-stop chain | NC | TRUE | FALSE = E-stop pressed |
| `stVirtualIO.bSafetyRelayFB` | DI_SafetyRelay_OK | NO | TRUE | FALSE = relay fault |
| `stVirtualIO.abLimitPos[1]` | DI_LimitPos_Ax1 — positive limit Axis 1 | NC | TRUE | FALSE = limit tripped |
| `stVirtualIO.abLimitNeg[1]` | DI_LimitNeg_Ax1 — negative limit Axis 1 | NC | TRUE | FALSE = limit tripped |
| `stVirtualIO.abLimitPos[2]` | DI_LimitPos_Ax2 — positive limit Axis 2 | NC | TRUE | FALSE = limit tripped |
| `stVirtualIO.abLimitNeg[2]` | DI_LimitNeg_Ax2 — negative limit Axis 2 | NC | TRUE | FALSE = limit tripped |
| `stVirtualIO.abHomeSwitch[1]` | DI_HomeSwitch_Ax1 — home switch Axis 1 | NO | FALSE | TRUE = at home position |
| `stVirtualIO.abHomeSwitch[2]` | DI_HomeSwitch_Ax2 — home switch Axis 2 | NO | FALSE | TRUE = at home position |
| `stVirtualIO.bSensor1` | DI_SensorA — inductive sensor A | NO | FALSE | TRUE = target detected |
| `stVirtualIO.bSensor2` | DI_SensorB — inductive sensor B | NO | FALSE | TRUE = target detected |

---

## 3. Virtual Digital Outputs (readback only)

These are written by the PLC logic and readable in simulation for verification. Do not write to these manually — they reflect real output logic.

| ST field | Corresponds to | Verify by |
|---------|---------------|----------|
| `stVirtualIO.bReadyLamp` | DO_Beacon_Green | Should be TRUE in MANUAL/AUTO modes |
| `stVirtualIO.bFaultLamp` | DO_Beacon_Red | Should be TRUE in FAULT mode |
| `stVirtualIO.bMotionLamp` | DO_Beacon_Amber | Should be TRUE during HOMING/motion |
| `stVirtualIO.bHomedLamp` | DO_DriveEnable_Ax1 (proxy) | TRUE when drive enabled |
| `stVirtualIO.bSafetyRelayCmd` | DO_BrakeRelease_Ax1 (proxy) | TRUE when brake released |

---

## 4. Simulation Test Scenarios — I/O Setup Table

Quick reference for each FAT test scenario:

| Test | Pre-condition I/O state | Action during test |
|------|------------------------|-------------------|
| TR01 Init | All defaults (bEStop=T, relayFB=T, limits=T) | No I/O change needed |
| TR02 Homing | Defaults + abHomeSwitch[1]=FALSE | Set abHomeSwitch[1]=TRUE when axis reaches home |
| TR03 Abs move | Homed state | No I/O change |
| TR04 Rel move | Axis at 100.0mm | No I/O change |
| TR05 Jog | MANUAL mode | No I/O change |
| TR06 Soft limit | MANUAL mode | No I/O change (command rejects by software) |
| TR07 E-stop | Axis moving | Set bEStop := FALSE |
| TR08 Fault reset | FAULT mode (from TR07) | Set bEStop := TRUE, then acknowledge, then reset |
| TR09 Alarm ack | Any alarm active | Use CMD_ACK_ALARM command |
| TR10 Trace | System running >2min | Set fbTrace.bExportTrigger := TRUE |
| TR11 Warm restart | MANUAL mode | TwinCAT PLC restart (no I/O change) |
| TR12 Cold restart | Any mode | TwinCAT system restart (no I/O change) |

---

## 5. Phase 2 Hardware Mapping

When bSimulationMode is set to FALSE for hardware integration, each virtual field maps to a physical EtherCAT terminal channel:

| Virtual field | Phase 2 physical variable | Terminal |
|--------------|--------------------------|---------|
| stVirtualIO.bEStop | GVL_IO.bPhysEStop | EL1008 Ch1 |
| stVirtualIO.bSafetyRelayFB | GVL_IO.bPhysSafetyRelayFB | EL1008 Ch2 |
| stVirtualIO.abHomeSwitch[1] | GVL_IO.bPhysHomeSwitch1 | EL1008 Ch3 |
| stVirtualIO.abHomeSwitch[2] | GVL_IO.bPhysHomeSwitch2 | EL1008 Ch4 |
| stVirtualIO.abLimitPos[1] | GVL_IO.bPhysLimitPos1 | EL1008 Ch5 |
| stVirtualIO.abLimitNeg[1] | GVL_IO.bPhysLimitNeg1 | EL1008 Ch6 |
| stVirtualIO.abLimitPos[2] | GVL_IO.bPhysLimitPos2 | EL1008 Ch7 |
| stVirtualIO.abLimitNeg[2] | GVL_IO.bPhysLimitNeg2 | EL1008 Ch8 |

---

## 6. Document Control

| Rev | Date | Author | Change |
|-----|------|--------|--------|
| 1.0 | 2026-06-21 | Project team | Initial issue |

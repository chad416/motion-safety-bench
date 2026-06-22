# I/O List
## Industrial Motion and Safety Bench

**Document:** docs/04_IO_list.md  
**Revision:** 1.0  
**Date:** 2026-06-20  
**Derived from:** docs/02_FDS.md Section 9  
**Status:** APPROVED — Baseline for simulation I/O mapping and Phase 2 wiring  
**Safety note:** Safety-oriented design only. No certified SIL/PL claimed.

---

## 1. Digital Inputs

| Tag name | Description | Signal type | Logic | NC/NO | 24V source | Sim default | Phase 2 terminal | Ch |
|---------|------------|------------|-------|-------|-----------|------------|-----------------|-----|
| DI_EStop | E-stop mushroom button chain | BOOL | Active LOW (de-assert = E-stop pressed) | NC | External | TRUE | EL1008 | 1 |
| DI_SafetyRelay_OK | Safety relay (Pilz/Schmersal) output feedback | BOOL | Active HIGH = relay energised | NO | Relay | TRUE | EL1008 | 2 |
| DI_LimitPos_Ax1 | Positive hardware limit switch — Axis 1 | BOOL | NC — de-asserts when triggered | NC | 24V | TRUE | EL1008 | 3 |
| DI_LimitNeg_Ax1 | Negative hardware limit switch — Axis 1 | BOOL | NC — de-asserts when triggered | NC | 24V | TRUE | EL1008 | 4 |
| DI_HomeSwitch_Ax1 | Home switch — Axis 1 (24 V PNP preferred) | BOOL | NO — asserts at home position | NO | 24V | FALSE | EL1008 | 5 |
| DI_SensorA | Inductive sensor A — position detection | BOOL | NO — asserts when target present | NO | 24V | FALSE | EL1008 | 6 |
| DI_SensorB | Inductive sensor B — position detection | BOOL | NO — asserts when target present | NO | 24V | FALSE | EL1008 | 7 |
| DI_DriveReady_Ax1 | Drive ready status from EL7211 servo terminal | BOOL | Active HIGH = drive ready | NO | Internal | TRUE | EL7211 status bit | — |

**Note on NC logic:** DI_EStop and DI_LimitPos/Neg use NC (normally closed) contacts. A healthy circuit reads TRUE. Opening the contact (fault or wire break) reads FALSE. This ensures fail-safe behavior — a broken wire is detected as a fault.

---

## 2. Digital Outputs

| Tag name | Description | Signal type | Safe state | Voltage | Phase 2 terminal | Ch |
|---------|------------|------------|-----------|---------|-----------------|-----|
| DO_DriveEnable_Ax1 | Drive enable — Axis 1 EL7211 | BOOL | FALSE (off) | 24V DC | EL2008 | 1 |
| DO_BrakeRelease_Ax1 | Motor brake release — Axis 1 (energise to release) | BOOL | FALSE (brake applied) | 24V DC | EL2008 | 2 |
| DO_Beacon_Green | Status beacon — green (running/healthy) | BOOL | FALSE | 24V DC | EL2008 | 3 |
| DO_Beacon_Amber | Status beacon — amber (homing/warning) | BOOL | FALSE | 24V DC | EL2008 | 4 |
| DO_Beacon_Red | Status beacon — red (FAULT) | BOOL | FALSE | 24V DC | EL2008 | 5 |

---

## 3. Axis References

| Tag name | Type | Description | Phase 2 drive | Motor |
|---------|------|------------|--------------|-------|
| Axis_1 | AXIS_REF | Primary servo axis | Beckhoff EL7211-0010 | AM3111 or AM8121 (48V, resolver or OCT) |
| Axis_2 | AXIS_REF | Optional second axis | Beckhoff EL7211-0010 | AM3111 or AM8121 |

---

## 4. Virtual I/O Map (Simulation)

When `ConfigPackage.bSimulationMode := TRUE`, physical I/O mapped through `stVirtualIO`. 

To simulate test scenarios during Simulation FAT, the engineer sets these variables directly in TwinCAT Online → Watch window or via TestHarness.st:

| Test scenario | Variable to set | Value |
|--------------|---------------|-------|
| Simulate E-stop press | `GVL_VirtualIO.stVirtualIO.bEStop` | FALSE |
| Release E-stop | `GVL_VirtualIO.stVirtualIO.bEStop` | TRUE |
| Simulate safety relay trip | `GVL_VirtualIO.stVirtualIO.bSafetyRelayFB` | FALSE |
| Trigger positive limit | `GVL_VirtualIO.stVirtualIO.abLimitPos[1]` | FALSE (NC opens) |
| Trigger negative limit | `GVL_VirtualIO.stVirtualIO.abLimitNeg[1]` | FALSE (NC opens) |
| Activate home switch | `GVL_VirtualIO.stVirtualIO.abHomeSwitch[1]` | TRUE |
| Trigger sensor A | `GVL_VirtualIO.stVirtualIO.bSensor1` | TRUE |

---

## 5. I/O State Word Encoding (TraceLogger)

For trace logging efficiency, digital inputs are packed into a WORD:

| Bit | Signal | 1 = |
|-----|--------|-----|
| 0 | DI_EStop | Chain healthy |
| 1 | DI_SafetyRelay_OK | Relay energised |
| 2 | DI_LimitPos_Ax1 | Limit active |
| 3 | DI_LimitNeg_Ax1 | Limit active |
| 4 | DI_HomeSwitch_Ax1 | At home |
| 5 | DI_SensorA | Target detected |
| 6 | DI_SensorB | Target detected |
| 7 | DI_DriveReady_Ax1 | Drive ready |
| 8 | DO_DriveEnable_Ax1 | Drive enabled |
| 9 | DO_BrakeRelease_Ax1 | Brake released |
| 10 | DO_Beacon_Green | Green on |
| 11 | DO_Beacon_Amber | Amber on |
| 12 | DO_Beacon_Red | Red on |
| 13–15 | Reserved | — |

---

## 6. Phase 2 Wiring Notes

| Signal | Wire colour convention | Cable type | Notes |
|--------|----------------------|-----------|-------|
| DI_EStop | Yellow | 0.5 mm² | NC circuit — both contacts wired through relay |
| Limit switches | White | 0.5 mm² | NC contacts; healthy circuit reads TRUE |
| Drive enable | Blue | 0.5 mm² | From EL2008 to EL7211 enable input |
| Motor power | Black | 1.5 mm² | 48V from PSU to EL7211 power input |
| Motor cable (OCT) | Per Beckhoff spec | OCT hybrid | AM81xx motors: single cable for power + feedback |

---

## 7. Document Control

| Rev | Date | Author | Change |
|-----|------|--------|--------|
| 1.0 | 2026-06-20 | Project engineering | Initial issue — derived from FDS Section 9 |
| 1.1 | 2026-06-21 | Project engineering | Corrected fail-safe limit defaults and as-built virtual tag names |

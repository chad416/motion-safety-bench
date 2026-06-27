# Simulation Plan
## Industrial Motion and Safety Bench — TwinCAT 3 Virtual Axis

**Document:** simulation/simulation_plan.md
**Revision:** 2.0
**Date:** 2026-06-21
**Platform:** TwinCAT 3 XAE (Windows)
**Status:** COMPLETE — modular FAT Run 02 accepted; retain this procedure for repeat testing
**Prerequisite:** Reviewed ST source in `plc/`, generated native objects in `twincat/RuntimeSimulation/`, and TwinCAT 3 XAE/XAR installed

---

## 1. What This Document Covers

Step-by-step instructions to:
1. Create a TwinCAT 3 project and import all ST modules
2. Configure a virtual axis (no hardware required)
3. Map virtual I/O for simulation
4. Run all 16 simulation FAT scenarios
5. Capture evidence (screenshots + trace exports)
6. Commit evidence to the repo

Total estimated time: 3–5 hours across multiple sessions.

---

## 2. Required Software (already installed)

| Software | Version | Purpose |
|---------|---------|---------|
| TwinCAT 3 XAE Shell | 3.1.4024.x | IDE + PLC + NC runtime |
| TC1200 TC3 PLC (trial) | — | PLC runtime license |
| TC1210 TC3 NC PTP (trial) | — | Motion NC license |
| Git | — | Commit evidence |

Trial licenses renew every 7 days: TwinCAT menu → License → Manage Licenses → Activate Trial License.

---

## 3. Project Creation — Step by Step

### 3.1 Create the TwinCAT Project

1. Open TwinCAT XAE Shell from Start menu
2. File → New → Project
3. Select: **TwinCAT Projects** → **TwinCAT XAE Project (XML format)**
4. Name: `MotionSafetyBench`
5. Location: the repository's `twincat/` directory
6. Click OK

### 3.2 Add PLC Project

1. In Solution Explorer: right-click **PLC** → Add New Item
2. Select: **Standard PLC Project**
3. Name: `MotionSafetyBenchPLC`
4. Click Add

### 3.3 Import ST Files

Import files in this exact order (dependency order):

| Order | File | TwinCAT object type |
|-------|------|-------------------|
| 1 | plc/Enumerations.st | DUT (Data Unit Type) |
| 2 | plc/Structures.st | DUT |
| 3 | plc/GVL_Constants.st | GVL (Global Variable List) |
| 4 | plc/GVL_VirtualIO.st | GVL |
| 5 | plc/GVL_IO.st | GVL |
| 6–15 | plc/*.st (all FBs) | POU (Function Block) — any order |
| 16 | plc/MAIN.st | POU (Program) |

**How to import each file:**
- Right-click the appropriate folder in PLC project tree
- Add → Existing Item → navigate to plc/ folder → select file
- OR: copy file content, add new POU/DUT/GVL, paste content

**Add Tc2_MC2 library:**
- Solution Explorer → PLC → References → right-click → Add Library
- Search: `Tc2_MC2` → add it
- This provides MC_Power, MC_Home, MC_MoveAbsolute, MC_MoveRelative, MC_Stop, MC_Reset, MC_Jog

### 3.4 Add NC Configuration (Virtual Axis)

1. Solution Explorer → right-click **Motion** → Add → NC/PTP NCI Configuration
2. Name: `NcConfig` → OK
3. Right-click **Axes** → Add → Axis
4. Axis name: `Axis_1`
5. Axis type: **Continuous Axis** → OK

**Configure virtual drive:**
1. Click on Axis_1
2. Tab: **Drive** → Drive type: **Simulated Drive**
3. Tab: **Enc** → Encoder type: **Simulation**
4. Set max velocity: 500 mm/s
5. Set max acceleration: 2000 mm/s²

**Repeat for Axis_2** (optional — same steps, name Axis_2).

### 3.5 Link Axes to PLC Variables

1. Click Axis_1 in NC tree
2. Tab: **PLC** → Link to PLC variable
3. Browse to: `MotionSafetyBenchPLC` → `MAIN` → `fbAxis` → `axis1Ref`
4. Click Link → OK
5. Repeat for Axis_2 → `axis2Ref`

### 3.6 Activate Configuration

1. Top menu: **TwinCAT** → **Activate Configuration**
2. Click OK on all prompts
3. Restart TwinCAT in RUN mode when asked → Yes

---

## 4. Virtual I/O Setup for Simulation

Because `bSimulationMode = TRUE` (default in ConfigPackage), all I/O reads from `GVL_VirtualIO.stVirtualIO` — no physical terminals needed.

**To manipulate virtual I/O during simulation:**

Method A — Watch Window (manual testing):
1. Build → PLC → Login (F5) → Run (F5)
2. View → Watch Window
3. Add variable: `GVL_VirtualIO.stVirtualIO`
4. Expand the struct — all fields are editable while PLC is running
5. Double-click a value to change it (e.g., set `bEStop := FALSE` to simulate E-stop press)

Method B — TestHarness (automated):
1. Set `fbTest.bRunAllTests := TRUE` in Watch Window
2. TestHarness automatically injects I/O states and commands
3. Results appear in `fbTest.astTestSummary`

**Default virtual I/O states (safe state for startup):**

| Variable | Default | Meaning |
|---------|---------|---------|
| stVirtualIO.bEStop | TRUE | E-stop chain healthy |
| stVirtualIO.bSafetyRelayFB | TRUE | Safety relay engaged |
| stVirtualIO.abLimitPos[1] | TRUE | Positive limit not tripped |
| stVirtualIO.abLimitNeg[1] | TRUE | Negative limit not tripped |
| stVirtualIO.abHomeSwitch[1] | FALSE | Not at home position |
| stVirtualIO.bSensor1 | FALSE | Sensor not active |

See simulation/virtual_io_map.md for full signal list.

---

## 5. Running the 16 Simulation FAT Scenarios

For each scenario: set up conditions, observe, capture evidence and note the result.

### TR01 — Power-up and Init

**Setup:** PLC running, all virtual I/O at defaults (safe state)  
**Action:** In Watch Window set `fbMode` inputs — system should auto-enter INIT  
**Expected:** `fbMode.eCurrentMode = MODE_INIT` (value = 1)  
**Evidence:** Screenshot of Watch Window showing eCurrentMode = 1  
**Save as:** `simulation/test_runs/TR01_init.png`

### TR02 — Homing Complete

**Setup:** System in INIT (TR01 passed)  
**Action:** Set `fbCommand.stHMICommand.eCommandType = CMD_HOME (8)`, `bExecute = TRUE`  
**During homing:** When system moves toward home, set `stVirtualIO.abHomeSwitch[1] := TRUE`  
**Expected:** `fbHoming.bAllAxesHomed = TRUE`, `fbMode.eCurrentMode = MODE_HOMING then MODE_MANUAL_JOG`  
**Evidence:** Screenshot showing HomeDone and mode transition  
**Save as:** `simulation/test_runs/TR02_homing.png`

### TR03 — Absolute Move

**Setup:** System in MODE_MANUAL_JOG (TR02 passed)  
**Action:** Set `fbCommand.stHMICommand.eCommandType = CMD_MOVE_ABSOLUTE (4)`, `fValue1 = 100.0`, `bExecute = TRUE`  
**Expected:** `fbAxis.astAxisStatus[1].fActualPosition ≈ 100.0`  
**Evidence:** TwinCAT Scope trace showing position vs time  
**Save as:** `simulation/test_runs/TR03_abs_move.png`

### TR04 — Relative Move

**Setup:** Axis at 100.0 mm (TR03 complete)  
**Action:** `eCommandType = CMD_MOVE_RELATIVE (5)`, `fValue1 = 50.0`, `bExecute = TRUE`  
**Expected:** `fActualPosition ≈ 150.0`  
**Evidence:** Scope trace or Watch Window screenshot  
**Save as:** `simulation/test_runs/TR04_rel_move.png`

### TR05 — Manual Jog

**Setup:** System in MODE_MANUAL_JOG  
**Action:** `eCommandType = CMD_JOG_POSITIVE (2)`, `bExecute = TRUE` — hold for 2 seconds, then `bExecute = FALSE`  
**Expected:** Position increases while jogging, stops on release  
**Evidence:** Scope trace showing position increasing then flat  
**Save as:** `simulation/test_runs/TR05_jog.png`

### TR06 — Soft Limit Rejection

**Setup:** System in MODE_MANUAL_JOG  
**Action:** `eCommandType = CMD_MOVE_ABSOLUTE (4)`, `fValue1 = 999.0` (beyond SoftLimitPositive = 300.0)  
**Expected:** Command rejected, `fbAlarm.nActiveAlarmCount > 0`  
**Evidence:** Screenshot showing alarm active, position unchanged  
**Save as:** `simulation/test_runs/TR06_soft_limit.png`

### TR07 — E-Stop During Motion

**Setup:** System in MODE_MANUAL_JOG or AUTO, axis moving  
**Action:** While axis moving: set `stVirtualIO.bEStop := FALSE`  
**Expected:** Axis stops immediately, `fbMode.eCurrentMode = MODE_FAULT (5)`, `fbSafety.bEStopActive = TRUE`  
**Evidence:** Screenshot of Watch Window showing FAULT mode + alarm active  
**Save as:** `simulation/test_runs/TR07_estop.png`

### TR08 — Fault Reset Cycle

**Setup:** System in FAULT (TR07 complete)  
**Action:** Set `stVirtualIO.bEStop := TRUE` (release E-stop), acknowledge alarm in Watch Window, `fbCommand.stHMICommand.eCommandType = CMD_RESET (7)`, `bExecute = TRUE`  
**Expected:** Mode transitions: FAULT → RESET → INIT  
**Evidence:** Screenshot showing MODE_INIT after reset  
**Save as:** `simulation/test_runs/TR08_fault_reset.png`

### TR09 — Alarm Acknowledgement

**Setup:** Any active alarm  
**Action:** `eCommandType = CMD_ACK_ALARM (9)`, `nAlarmID = [active alarm ID]`, `bExecute = TRUE`  
**Expected:** Alarm `eState` changes to `ALARM_ACKNOWLEDGED (2)`  
**Evidence:** Screenshot of alarm state  
**Save as:** `simulation/test_runs/TR09_alarm_ack.png`

### TR10 — Trace Log Export

**Setup:** System has been running for at least 2 minutes  
**Action:** Set `fbTrace.bExportTrigger := TRUE` in Watch Window  
**Expected:** `fbTrace.nEventCount > 0`, `fbTrace.astRecentEvents` populated  
**Evidence:** Screenshot of trace events in Watch Window + export  
**Save as:** `simulation/test_runs/TR10_trace.png`

### TR11 — Warm Restart

**Setup:** System running in MODE_MANUAL_JOG  
**Action:** TwinCAT → PLC → Logout → Login → Run (keeps configuration)  
**Expected:** System re-enters INIT cleanly, no stale alarms, no data corruption  
**Evidence:** Screenshot of clean INIT after restart  
**Save as:** `simulation/test_runs/TR11_warm_restart.png`

### TR12 — Cold Restart

**Setup:** System in any mode  
**Action:** TwinCAT → Restart TwinCAT System → reconnect and run  
**Expected:** System starts from INIT with all defaults loaded  
**Evidence:** Screenshot of clean INIT from cold start  
**Save as:** `simulation/test_runs/TR12_cold_restart.png`

### TR13-TR16 - Expanded Fault And State Tests

The current accepted modular FAT extends the original twelve manual scenarios with four additional automated cases:

| Test | Focus | Expected result |
|---|---|---|
| TR13 | Warm restart command-path state | No stale motion command; axis remains standstill |
| TR14 | Cold defaults | Virtual safe defaults restored |
| TR15 | Watchdog timeout | Motion inhibited, FAULT observed, reset restores healthy state |
| TR16 | Invalid OFF-state move | Command rejected and no motion occurs |

---

## 6. TwinCAT Scope — Trace Evidence Capture

TwinCAT Scope View records variable trends over time — this is the primary evidence for move accuracy.

**How to set up Scope:**
1. View → TwinCAT Scope View
2. File → New Scope Project
3. Right-click chart → Add Signal
4. Browse to: `MotionSafetyBenchPLC.MAIN.fbAxis.astAxisStatus[1].fActualPosition`
5. Add also: `fActualVelocity`, `fbMode.eCurrentMode`
6. Press Record (red circle) before starting the motion test
7. Press Stop after motion completes
8. File → Export → CSV → save to `simulation/test_runs/scope_TR03.csv`

---

## 7. Evidence Commit Procedure

Run the repository validator and stage only the reviewed evidence:

```powershell
Set-Location <repository-root>
.\tools\validate_project.ps1
git add simulation\test_runs outputs\motion-safety-bench
```

Commit from a feature branch after validation succeeds:

```powershell
git commit -m "test: record accepted modular TwinCAT FAT evidence"
git push -u origin <feature-branch>
```

---

## 8. Quality Gate — Simulation FAT Complete

All of the following must be true before hardware procurement is authorized:

| Gate | Check |
|------|-------|
| SIM-QG1 | PASS - Run 02 JSON records TR01-TR16 as passed; CSV/PNG and workbook are retained |
| SIM-QG2 | PASS — TR07 validates the E-stop fault response |
| SIM-QG3 | PASS — TR08 validates the FAULT→RESET→INIT recovery |
| SIM-QG4 | PASS — trace behavior is covered by the modular suite and retained baseline |
| SIM-QG5 | PASS — physical addresses are isolated to `GVL_IO` |
| SIM-QG6 | PASS — accepted runs use the deterministic simulation plant |

---

## 9. Document Control

| Rev | Date | Author | Change |
|-----|------|--------|--------|
| 1.0 | 2026-06-21 | Project team | Initial issue |
| 2.0 | 2026-06-21 | Project team | Record accepted modular FAT and portable evidence workflow |

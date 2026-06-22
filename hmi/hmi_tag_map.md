# HMI Tag and Command Contract

**Revision:** 1.0 — 2026-06-21

## Read-only status

| HMI tag | PLC symbol | Type | Update | Purpose |
|---|---|---|---|---|
| `Machine.Mode` | `MAIN.fbHMI.stHMIData.eCurrentMode` | ENUM | 100 ms | Current mode |
| `Machine.Simulation` | `MAIN.fbHMI.stHMIData.bSimulationMode` | BOOL | 500 ms | Simulation banner |
| `Machine.DataStale` | `MAIN.fbHMI.stHMIData.bHMIDataStale` | BOOL | 250 ms | Communication warning |
| `Axis1.Position` | `MAIN.fActualPosition` | LREAL | 50 ms | Actual position |
| `Axis1.Velocity` | `MAIN.fActualVelocity` | LREAL | 50 ms | Actual velocity |
| `Axis1.State` | `MAIN.fbHMI.stHMIData.astAxisStatus[1].eAxisState` | ENUM | 100 ms | Motion state |
| `Axis1.Enabled` | `MAIN.fbHMI.stHMIData.astAxisStatus[1].bEnabled` | BOOL | 100 ms | Enable status |
| `Axis1.Homed` | `MAIN.fbHMI.stHMIData.astAxisStatus[1].bHomed` | BOOL | 100 ms | Homing status |
| `Safety.SafeToRun` | `MAIN.fbHMI.stHMIData.stSafetyStatus.bSafeToRun` | BOOL | 50 ms | Overall permit |
| `Safety.EStopActive` | `MAIN.fbHMI.stHMIData.stSafetyStatus.bEStopActive` | BOOL | 50 ms | E-stop status |
| `Alarm.Count` | `MAIN.fbHMI.stHMIData.nActiveAlarmCount` | UINT | 250 ms | Alarm badge |
| `Alarm.HighestSeverity` | `MAIN.fbHMI.stHMIData.eHighestSeverity` | ENUM | 250 ms | Banner priority |
| `Test.Running` | `MAIN.bSimulationRunning` | BOOL | 100 ms | Test state |
| `Test.Complete` | `MAIN.bSimulationComplete` | BOOL | 100 ms | Test complete |
| `Test.Passed` | `MAIN.bSimulationPassed` | BOOL | 100 ms | Suite result |
| `Test.Current` | `MAIN.nCurrentTest` | UINT | 100 ms | Current scenario |
| `Test.PassedCount` | `MAIN.nTestsPassed` | UINT | 100 ms | FAT count |
| `Trace.Recent` | `MAIN.fbHMI.stHMIData.astRecentEvents` | ARRAY | 500 ms | Event list |

## Command write structure

All production HMI commands write fields in `MAIN.fbHMI.stHMICommand`, then pulse `bExecute`. The HMI never writes internal module state.

| Command | `eCommandType` | Fields |
|---|---:|---|
| Mode request | 1 | `eTargetMode` |
| Jog positive/negative | 2/3 | `nAxisIndex`, `fValue1` velocity; maintain `bExecute` |
| Absolute move | 4 | `nAxisIndex`, `fValue1` target, `fValue2` velocity |
| Relative move | 5 | `nAxisIndex`, `fValue1` distance, `fValue2` velocity |
| Stop | 6 | `nAxisIndex` |
| Reset | 7 | — |
| Home | 8 | — |
| Acknowledge alarm | 9 | `nAlarmID` |
| Reset cleared alarms | 10 | — |

## Write handshake

1. Verify `bHMIDataStale = FALSE` and relevant permit is true.
2. Populate command fields while `bExecute = FALSE`.
3. Set `bExecute = TRUE` for one update for edge commands.
4. Return `bExecute = FALSE`.
5. Display `eLastCommandStatus` and rejection text.

Jog deliberately differs: `bExecute` stays true only while the button is held.

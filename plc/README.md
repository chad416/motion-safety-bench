# PLC Module Reference

The `plc/` directory is the reviewed source of truth. Each function block has an executable cyclic body; there are no implementation TODO stubs.

| Source | Responsibility |
|---|---|
| `Enumerations.st` | Modes, states, commands, alarms, trace and test enums |
| `Structures.st` | Configuration, status, command, alarm, trace, HMI and test structures |
| `GVL_Constants.st` | Fixed capacities and axis count |
| `GVL_VirtualIO.st` | Simulation I/O image |
| `GVL_IO.st` | Unlocated physical I/O symbols for TwinCAT channel linking |
| `ConfigPackage.st` | Defaults and validation |
| `SafetyManager.st` | Input selection and safety permits |
| `AlarmManager.st` | Alarm lifecycle/history projection |
| `ModeManager.st` | Seven-mode state machine and permits |
| `CommandParser.st` | Edge qualification and command validation |
| `HomingManager.st` | Timeout/retry protected homing abstraction |
| `AxisManager.st` | Deterministic plant or PLCopen path |
| `TraceLogger.st` | Bounded event ring buffer |
| `HMIModel.st` | Read-only operator data projection |
| `TestHarness.st` | Sixteen simulation FAT scenarios |
| `MAIN.st` | Fixed cyclic integration order and stable ADS aliases |

## Generate the native TwinCAT project

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\generate_twincat_project.ps1
```

This produces native objects under `twincat/RuntimeSimulation/`. Generated IDs are deterministic, so repeated runs are diffable.

## Libraries

- `Tc2_Standard`
- `Tc2_System`
- `Tc3_Module`
- `Tc2_MC2`

## Simulation and hardware modes

`FB_ConfigPackage.stMachineConfig.bSimulationMode = TRUE` selects the software plant and virtual I/O. Set it to `FALSE` only after linking `axis1Ref`/`axis2Ref`, linking each EtherCAT channel to the symbolic `GVL_IO` variable, verifying I/O polarity and completing the hardware commissioning entry gates. No fixed `%I/%Q` process-image address is permitted in reusable source.

## Safety statement

The source demonstrates safety-oriented control architecture. It is not a certified safety application and cannot replace a safety relay/controller, risk assessment or stopping-time validation.

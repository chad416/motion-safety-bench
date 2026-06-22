# TwinCAT Runtime System

`MotionSafetyBench.tsproj` is the runnable TwinCAT system configuration for the
local XAR simulation target. It contains the 10 ms PLC task, NC simulation axis,
and PLC runtime instance on ADS port 852.

The system project references the deterministic PLC application at
`../RuntimeSimulation/MotionSafetyBenchPLC.plcproj`; reviewed logic remains in
`plc/` and is regenerated with:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\generate_twincat_project.ps1
```

Compile the complete runtime solution with:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_twincat_solution.ps1 `
  -SolutionRelativePath 'twincat\MotionSafetyBenchRuntime.sln'
```

Activation and download change the local TwinCAT runtime configuration and are
therefore separate commissioning gates. The checked-in system configuration
contains no AMS route credentials or hardware-specific EtherCAT devices.

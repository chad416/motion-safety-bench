# Industrial Motion and Safety Bench — Case Study

## Executive summary

This project demonstrates a software-first approach to an industrial servo bench using TwinCAT 3 and IEC 61131-3 Structured Text. The system models one primary linear axis with a second-axis-ready architecture, seven machine modes, safety-oriented interlocks, alarms, homing, command validation, trace logging, HMI data aggregation and twelve repeatable FAT scenarios.

The software was commissioned on a Windows 11 laptop before hardware selection. A deterministic plant model generated real position/velocity signals in a 10 ms PLC task. The generated modular application compiled, downloaded to ADS port 852, passed all twelve FAT scenarios, and autostarted after a TwinCAT runtime restart. The earlier recovery baseline remains separately traceable with 25,445 TwinCAT Scope samples.

## Engineering problem

A credible automation portfolio cannot be only a collection of PLC code screenshots. It must show a traceable path from requirements to design, implementation, verification, operator experience and hardware readiness—while avoiding false safety claims.

The project therefore had four constraints:

1. Prove logic before buying a servo system.
2. Use industrial architecture and terminology relevant to Beckhoff/TwinCAT roles.
3. Retain evidence rather than relying on live demonstrations alone.
4. Separate standard-PLC safety-oriented behavior from certified safety functions.

## Architecture

The application is split into focused function blocks:

- `FB_ConfigPackage`: defaults and parameter validation.
- `FB_SafetyManager`: virtual/physical input selection and same-scan permits.
- `FB_AlarmManager`: alarm lifecycle and severity aggregation.
- `FB_ModeManager`: OFF/INIT/HOMING/MANUAL/AUTO/FAULT/RESET transitions.
- `FB_CommandParser`: edge-qualified, mode/safety-validated commands.
- `FB_HomingManager`: multi-step, timeout-protected homing abstraction.
- `FB_AxisManager`: software plant or PLCopen motion path.
- `FB_TraceLogger`: bounded ring-buffer events.
- `FB_HMIModel`: read-only operator status projection.
- `FB_TestHarness`: the same command path used by the HMI.

Reviewed ST source is converted deterministically into native `.TcDUT`, `.TcGVL` and `.TcPOU` objects. Machine-specific ADS routes and generated boot files remain outside Git.

## Verification

The FAT suite covers startup, homing, absolute/relative moves, jog, soft-limit rejection, E-stop during motion, reset, alarm acknowledgement, trace logging, warm restart and cold defaults.

Accepted modular Run 02 produced:

- Zero TwinCAT project build errors.
- 12 tests run, 12 passed, 0 failed.
- Live ADS position/velocity timeline on port 852.
- Successful forced download and PLC start.
- Generated boot project with autostart.
- ADS returned to `Run` after runtime restart without another download.

Recovery baseline Run 01 produced:

- 12 tests run, 12 passed, 0 failed.
- 25,445 samples per Scope channel at 10 ms.
- Position range 0–215 mm.
- Velocity range 0–200 mm/s.
- 143 non-zero velocity samples.

The evidence workbook retains both evidence chains: Run 02 provides the modular test table and live ADS timeline; Run 01 retains raw Scope data and the isolated active-motion window. Formula-driven KPIs and SHA-256 checksums keep the records auditable without presenting the baseline as the modular result.

## Operator experience

The dependency-free HMI prototype provides:

- Animated linear-axis movement.
- Live position and velocity trend.
- Mode, safety, relay, homed, motion and fault status.
- E-stop simulation behavior.
- Twelve FAT result cards and an event log.

The production tag contract maps the prototype concepts to public PLC symbols. No HMI writes internal module state.

## Troubleshooting lessons

- Windows VBS/Hyper-V can prevent TwinCAT real-time operation; use the signed Beckhoff configuration tool and plan BitLocker recovery/suspension before firmware changes.
- `Soft Drive (Object)` requires valid TCom drive/encoder objects. Selecting it casually caused data-interface errors; the project returned to standard mapping while the software plant supplied simulation motion.
- Plain `.st` files added as content are not equivalent to native TwinCAT objects. A deterministic generator now creates portable native objects and stable IDs.
- A passed simulation is not evidence of motor sizing, wiring, stopping time or certified safety performance; these remain SAT responsibilities.

## Hardware path

The preferred Phase 2 architecture uses EK1100, EL1008, EL2008, EL7211-0010, a compatible 48 V servo, industrial sensors, a certified safety relay and guarded linear mechanics. Procurement remains blocked until load/inertia sizing and safety review are complete.

## Result

The repository demonstrates requirements discipline, modular ST, virtual commissioning, evidence-led testing, HMI thinking and honest safety boundaries. It is designed to be discussed in an interview and extended on a real Beckhoff bench without rewriting the core behavior model.

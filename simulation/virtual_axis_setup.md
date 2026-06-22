# TwinCAT Virtual Axis and Software-Plant Setup

**Revision:** 1.0 — 2026-06-21

## Selected architecture

The accepted Phase 1 baseline is a deterministic software plant in `FB_AxisManager`/the runtime regression POU. It exposes position and velocity as normal PLC symbols and does not require a physical drive. The NC axis remains available for later mapping but is not falsely represented as the source of Run 01 motion.

## NC configuration

1. Add an NC/PTP configuration and continuous `Axis 1`.
2. Leave **Axis Type** as `Standard (Mapping via Encoder and Drive)` unless real NC simulation objects are deliberately configured.
3. Do not choose `Soft Drive (Object)` without a valid TCom drive and encoder object; doing so produces `Connect to data interface failed` errors.
4. Configure engineering limits to match the software baseline:
   - velocity 500 mm/s
   - acceleration/deceleration 2000 mm/s²
   - positive soft limit 300 mm
   - negative soft limit −10 mm
5. Link an `AXIS_REF` only when executing the PLCopen hardware/NC path.

## Software-plant mode

- `FB_ConfigPackage.stMachineConfig.bSimulationMode = TRUE` selects virtual I/O and plant behavior.
- The plant integrates velocity using the 10 ms task period.
- Move commands are checked against soft limits before a target is accepted.
- Safety loss sets velocity to zero and removes the software enable immediately.
- Homing uses abstract seek/set-position requests so the same state machine can later drive PLCopen motion.

## Scope channels

Connect ADS port 852 symbols:

- `MAIN.fActualPosition`
- `MAIN.fActualVelocity`

Add both acquisitions to the YT Chart Axis Group, start recording before triggering the suite, then export CSV to `simulation/test_runs/`.

## Reproducible project generation

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\generate_twincat_project.ps1
```

The generator creates deterministic native TwinCAT DUT, GVL and POU objects under `twincat/RuntimeSimulation/`. Reviewed source remains under `plc/`; generated object IDs are stable.

## Hardware transition

Set simulation mode `FALSE`, link `axis1Ref`/`axis2Ref`, verify the EtherCAT process image and repeat SAT. Do not reuse simulation acceptance as hardware acceptance.

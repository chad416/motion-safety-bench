# Engineering Walkthrough Script

## 1. Requirements and boundaries

- Start with the URS: one/two-axis portfolio bench, virtual first, hardware later.
- Explain the FDS seven-mode state model and fail-safe input semantics.
- State explicitly that the project is not a certified safety application.

## 2. Cyclic architecture

Walk through the fixed order in `MAIN.st`:

1. Configuration
2. Safety input selection/interlocks
3. Alarm evaluation
4. Mode state machine
5. Command validation
6. Homing abstraction
7. Axis software plant/PLCopen path
8. Trace events
9. HMI projection
10. Test harness

Discuss the intentional one-scan pipeline between axis/homing faults and AlarmManager to avoid cyclic data dependency.

## 3. Safety-oriented controls

- E-stop and relay feedback are fail-safe inputs.
- Safety loss stops/inhibits software motion before ordinary command handling.
- Fault reset requires a healthy chain.
- Acknowledgement does not clear the cause.
- The Phase 2 certified relay remains the energy-removal authority.

## 4. Motion and homing

- CommandParser rejects prohibited modes, unsafe conditions and invalid axes.
- AxisManager checks final absolute/relative targets against limits.
- Simulation integrates velocity with the 10 ms task period.
- Hardware mode calls PLCopen blocks against linked `AXIS_REF` values.
- Homing has seek, backoff, slow re-approach, set-position, retry and timeout states.

## 5. Reproducibility

- Reviewed ST source lives under `plc/`.
- `generate_twincat_project.ps1` generates native objects with stable GUIDs.
- Local ADS routes, boot files and licenses are ignored.
- The repository validator checks TODOs/placeholders, XML, evidence and forbidden tracked artifacts.

## 6. Verification evidence

- Show the raw Scope CSV and evidence workbook.
- Explain the active-window extraction and formula-driven KPIs.
- Relate each FAT scenario to a cause/effect requirement.
- Be clear that Run 01 is the platform-recovery baseline and Run 02 is the independently compiled/downloaded modular FAT: 12/12 passed with boot-autostart verification.

## 7. HMI

- Demonstrate animated axis, trend, status lamps, FAT page and event log.
- Explain public status tags and the command handshake.
- Trigger E-stop to show operator feedback without claiming the browser button is a safety device.

## 8. Hardware transition

- Review the provisional EtherCAT topology and procurement hold points.
- Emphasize motor/drive/cable compatibility and inertia/duty sizing.
- Close with SAT: wiring, I/O polarity, E-stop energy removal, limits, homing repeatability and full regression.

## Interview questions to invite

- Why use a software plant instead of an NC simulation object?
- How does the reset path prevent bypassing safety?
- What changes when moving from simulation to EL7211?
- How are alarms latched and acknowledged?
- What evidence would be required before production release?

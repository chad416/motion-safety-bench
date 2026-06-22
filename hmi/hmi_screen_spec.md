# HMI Screen Specification

**Revision:** 1.0 — 2026-06-21
**Prototype:** `hmi/prototype/index.html`

## Design goals

- Make mode, safety, motion and alarm state readable within two seconds.
- Keep commands separate from status and route every command through `FB_CommandParser`.
- Never use color as the only status indicator.
- Display an explicit `SIMULATION MODE` banner and a stale-data warning.
- Provide no UI control capable of bypassing a PLC interlock.

## Navigation

### Overview

- Machine mode and transition detail.
- Axis 1 actual/target position, velocity and state.
- Animated linear-axis carriage and limit/home markers.
- Safety chain, relay, homed, motion and fault lamps.
- Live position/velocity trend.
- Run/pause/reset test controls for simulation demonstration.
- Prominent E-stop simulation button; physical installations use the real hardwired E-stop.

### FAT tests

- Twelve scenario cards with NOT RUN/RUNNING/PASS/FAIL state.
- Aggregate pass count.
- Expected behavior text for each test.
- Test controls disabled when simulation mode is false.

### Diagnostics

- Recent mode, alarm, motion and test events.
- Runtime, task time, ADS port and evidence status.
- Safety disclaimer and software/hardware baseline identity.

## Production TwinCAT HMI screens

| Screen | Purpose | Key controls |
|---|---|---|
| Overview | Current machine condition | Mode request, stop, navigation |
| Axis | Detailed motion state | Absolute/relative move subject to permits |
| Manual | Setup and jog | Hold-to-run jog, home, stop |
| Auto | Sequence operation | Start/pause/stop when AUTO permitted |
| Alarms | Active/history lifecycle | Acknowledge, reset when permitted |
| Diagnostics | I/O, trace, communications | Trace export, no direct safety override |
| Configuration | Controlled parameters | Edit only OFF/INIT with access control |

## Interaction rules

- Jog is a maintained command; release removes the execute level.
- Move/home/reset commands use a rising edge and provide acceptance/rejection feedback.
- E-stop status is read from PLC safety state, never inferred from an HMI button.
- Alarm acknowledgement does not clear an active source condition.
- Configuration changes require validation before becoming active.
- Loss of heartbeat for two seconds displays `PLC DATA STALE` and disables commands.

## Visual language

| State | Color | Text/icon requirement |
|---|---|---|
| Healthy/ready | Green | `HEALTHY`, check/lamp |
| Motion/transition | Amber/cyan | Mode or `MOVING` text |
| Fault/critical | Red | Alarm ID and `FAULT`; optional flash for critical |
| Disabled/offline | Gray | `OFF`, `DISABLED` or `STALE` text |

## Prototype execution

```powershell
node .\tools\serve_hmi.mjs
```

Open `http://127.0.0.1:4173`. The prototype has no external dependencies and is suitable for portfolio demonstration. It is not connected to ADS; the production tag contract is defined separately.

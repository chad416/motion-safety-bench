# Phase 2 Wiring Plan

**Revision:** 1.0 — 2026-06-21
**Status:** Design concept; must be converted to controlled electrical drawings before construction

## Power domains

- Protective earth bonds enclosure, DIN rail, drive/motor PE and exposed conductive mechanics.
- 24 VDC control power supplies EtherCAT I/O, sensors, lamps and relay interfaces.
- 48 VDC drive power supplies the servo terminal/motor circuit.
- Control and motor power are fused separately.
- Motor/OCT and encoder cables follow Beckhoff shielding/termination requirements.

## Digital input allocation

| EL1008 channel | Signal | Field behavior |
|---:|---|---|
| 1 | E-stop safety relay status | Healthy = TRUE |
| 2 | Safety relay feedback | Energized/healthy = TRUE |
| 3 | Axis 1 positive limit | NC healthy = TRUE |
| 4 | Axis 1 negative limit | NC healthy = TRUE |
| 5 | Axis 1 home sensor | Active at reference |
| 6 | Sensor A | Application input |
| 7 | Sensor B | Application input |
| 8 | Spare/drive-ready | Document at commissioning |

## Digital output allocation

| EL2008 channel | Signal | Safe state |
|---:|---|---|
| 1 | Drive-enable interface | FALSE |
| 2 | Brake-release interface | FALSE / brake applied |
| 3 | Green beacon | FALSE |
| 4 | Amber beacon | FALSE |
| 5 | Red beacon | FALSE |
| 6–8 | Spare | FALSE |

## Safety boundary

The E-stop uses a certified dual-channel relay or safety controller to remove/disable hazardous motion energy. Standard PLC outputs are indication and controlled-stop requests only. The standard PLC is not the sole E-stop path.

## Segregation and labeling

- Separate motor power, mains and low-voltage signal wiring.
- Use ferrules, terminal labels and wire numbers matching drawings.
- Terminate shields per manufacturer guidance, normally with low-impedance 360° bonding.
- Label all field devices and record terminal-to-tag continuity.
- Preserve spare channels and PE terminals.

## Pre-energization checks

- [ ] PE continuity verified.
- [ ] Polarity and voltage checked with drive disconnected.
- [ ] Fuses/breakers match conductor and equipment ratings.
- [ ] E-stop relay tested independently of PLC.
- [ ] NC limit polarity confirmed.
- [ ] Motor/feedback/cable compatibility confirmed.
- [ ] Mechanical travel clear and guarded.

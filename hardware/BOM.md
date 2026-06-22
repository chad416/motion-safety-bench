# Bill of Materials — Phased

**Revision:** 1.0 — 2026-06-21
**Procurement status:** HOLD until software FAT gate and mechanical sizing

## Phase 1 — software

| Item | Qty | Status | Cost level |
|---|---:|---|---|
| Windows engineering laptop | 1 | Existing | Existing |
| TwinCAT 3 XAE 4024.75 | 1 | Installed | Free engineering environment |
| TC1200 PLC / TC1210 NC trial | 1 | Active as required | Trial |
| Git/GitHub repository | 1 | Existing | Free |
| Browser HMI prototype | 1 | Implemented | No external dependency |

## Phase 2 — preferred Beckhoff bench

| Item | Example | Qty | Purpose | Decision status |
|---|---|---:|---|---|
| EtherCAT coupler | EK1100 | 1 | Bus head | Preferred |
| Digital input | EL1008 | 1 | E-stop feedback, limits, home, sensors | Preferred |
| Digital output | EL2008 | 1 | Lamps, enable/brake interface | Preferred |
| Servo terminal | EL7211-0010 | 1 | 48 V servo control/OCT | Confirm after motor selection |
| Servo motor | AM81xx/AM31xx compatible | 1 | Primary axis | Size from inertia/duty calculation |
| 24 VDC PSU | Industrial DIN-rail, sized for I/O/controls | 1 | Controls | Size after load list |
| 48 VDC PSU | Sized for servo peak/continuous demand | 1 | Drive bus | Size after motor/drive calculation |
| Safety relay | Pilz/Schmersal equivalent | 1 | Certified E-stop function | Select with safety assessment |
| E-stop station | Dual-channel twist-release | 1 | Operator stop demand | Required |
| Limit switches | Industrial NC | 2 | End-of-travel protection | Required |
| Home sensor | Industrial proximity switch | 1 | Homing reference | Required |
| Enclosure/terminals/PE/fusing | IEC industrial parts | 1 set | Safe assembly | Required |
| Linear mechanics | Rail, carriage, coupling/guard | 1 set | Demonstration axis | Mechanical design pending |

## Budget bands

- Used Beckhoff proof bench: approximately €700–€1,200, condition dependent.
- New Beckhoff bench: approximately €1,800–€3,000 before mechanical fabrication.
- Low-cost stepper proof: approximately €500–€900, lower employer signal and different drive behavior.

Prices are planning bands, not quotations. Current supplier pricing, availability and exact part compatibility must be checked immediately before purchase.

## Release-to-purchase checklist

- [ ] Mechanical travel, payload, inertia and duty cycle documented.
- [ ] Motor/drive/PSU sizing calculation reviewed.
- [ ] Safety architecture selected by a competent person.
- [ ] Software FAT and evidence accepted.
- [ ] Wiring drawings and protective devices reviewed.
- [ ] Supplier compatibility and firmware/revision confirmed.

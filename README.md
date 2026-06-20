# Industrial Motion and Safety Bench

**Portfolio project:** PLC/ST, EtherCAT, TwinCAT 3, PLCopen motion, safety-oriented design, HMI, FAT/SAT evidence, commissioning documentation.

**Target roles:** Siemens Mobility, Honeywell Brno, Schneider Electric, Swisslog Healthcare

**Status:** Software phase in progress — deadline 15 July 2026

## Architecture

1-2 axis motion bench using TwinCAT 3 (IEC 61131-3 Structured Text), PLCopen motion blocks (MC_Power, MC_Home, MC_MoveAbsolute), EtherCAT fieldbus, safety-oriented E-stop design, HMI with alarm handling, trace logging, and simulation-first validation.

## Repository structure

| Folder | Contents |
|--------|---------|
| docs/ | URS, FDS, SDS, I/O list, network diagram, alarm list, FMEA, FAT, SAT, commissioning logbook |
| plc/ | 10 modular Structured Text source files |
| simulation/ | Simulation plan, virtual I/O map, test run evidence |
| hmi/ | HMI screen spec and tag map |
| hardware/ | BOM, wiring plan, procurement risk register |
| portfolio/ | Demo scripts and case study |

## Proof of engineering maturity

- Modular ST architecture (10 separate files, no monolithic program)
- PLCopen-compliant motion function blocks
- Multi-mode state machine: Off → Init → Homing → Manual/Jog → Auto → Fault → Reset
- Safety-oriented design (E-stop chain, safe stop concept) — not certified SIL/PL
- Simulation FAT evidence before any hardware procurement
- Complete FAT/SAT documentation

*Build date: 2026-06-20*

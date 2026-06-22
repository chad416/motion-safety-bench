# Hardware Procurement Risks

**Revision:** 1.0 — 2026-06-21

| Risk | Probability | Impact | Mitigation / hold point |
|---|---|---|---|
| Motor and EL7211 feedback variant incompatible | Medium | High | Buy matched motor/terminal/cable set; confirm electronic nameplate support |
| Used terminal hidden damage or obsolete revision | Medium | High | Obtain serial/revision, return right and test report |
| 48 V PSU undersized for peak torque | Medium | High | Size from drive data and duty cycle with margin |
| Mechanical inertia exceeds selected motor | Medium | High | Complete reflected-inertia and torque calculation first |
| Safety relay architecture incomplete | Medium | Critical | Independent safety review before order/build |
| NPN/PNP sensor mismatch with EL1008 wiring | Medium | Medium | Standardize sensor type and document common/reference wiring |
| Missing EtherCAT ESI/firmware compatibility | Low | Medium | Verify support in installed TwinCAT device repository |
| OCT/non-OCT cable mismatch | Medium | High | Freeze motor feedback/cabling variant as a system |
| Counterfeit or undocumented used parts | Medium | High | Reputable supplier, traceable labels, inspection |
| Long lead times | Medium | Medium | Separate mandatory core from optional expansion |
| Scope creep to two physical axes | High | Medium | Commission one axis first; second axis remains software-only |

## Procurement sequence

1. Freeze mechanical requirements.
2. Select motor/drive/cable as one compatibility package.
3. Select safety architecture.
4. Size power supplies, fusing and enclosure.
5. Confirm EtherCAT/I/O topology.
6. Buy one-axis core only.
7. Execute SAT before optional expansion.

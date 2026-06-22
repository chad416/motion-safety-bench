# Run 01 Runtime Baseline

`MAIN_Run01.TcPOU` is the exact minimal deterministic POU used to establish the first successful TwinCAT runtime, ADS and Scope evidence path on 2026-06-21.

It is retained for auditability only. The production architecture is the modular source under `plc/`, generated into native TwinCAT objects by `tools/generate_twincat_project.ps1`.

Run 01 evidence must not be presented as the modular build result. The modular project passed its independent compile/download gate and repeated FAT as `MotionSafetyBench_Modular_FAT_Run02`, which is retained separately.

# 90-Second Demonstration Script

**0–10 s — Problem**
“This is a software-first industrial motion and safety bench built in TwinCAT 3. I wanted to prove the control design before selecting servo hardware.”

**10–25 s — Architecture**
Show the repository/module diagram.
“The PLC separates configuration, safety, alarms, modes, commands, homing, motion, trace, HMI and testing. The test harness uses the same public command path as the operator interface.”

**25–50 s — Live HMI**
Click **Run 12-test simulation**.
“This is the deterministic software plant. Position and velocity run in a 10 ms model. The suite exercises homing, absolute and relative moves, jog, soft limits, E-stop, reset and restart behavior.”

**50–62 s — Safety behavior**
Press/release **E-STOP** during a move.
“Safety loss inhibits motion and enters FAULT. This standard PLC demonstrates safety-oriented behavior; it does not claim certified SIL or PL.”

**62–78 s — Evidence**
Open the evidence workbook/plot.
“The modular TwinCAT application compiled, downloaded, and passed all 12 FAT scenarios. Run 02 captures its live ADS timeline; Run 01 retains 25,445 Scope samples from the platform-recovery baseline.”

**78–90 s — Hardware path**
Show the BOM/network diagram.
“The hardware plan moves to EK1100, EL1008/EL2008 and EL7211 after motor sizing and safety review. Hardware validates the baseline through SAT; it does not replace software FAT.”

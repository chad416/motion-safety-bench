PROGRAM PRG_Main
VAR
    fbConfig    : FB_ConfigPackage;
    fbSafety    : FB_SafetyManager;
    fbAlarm     : FB_AlarmManager;
    fbMode      : FB_ModeManager;
    fbCommand   : FB_CommandParser;
    fbHoming    : FB_HomingManager;
    fbAxis      : FB_AxisManager;
    fbTrace     : FB_TraceLogger;
    fbHMI       : FB_HMIModel;
    fbTest      : FB_TestHarness;
END_VAR

(* ========== CYCLIC CALL ORDER - fixed, do not reorder ========== *)

(* Step 1 - Config must run first so all parameters are current *)
fbConfig.Cyclic();

(* Step 2 - Safety reads I/O before any motion decision *)
fbSafety.Cyclic();
(* TODO: wire config to safety *)
fbSafety.bSimulationMode := fbConfig.bSimulationMode;
fbSafety.stConfig := fbConfig.stMachineConfig.stSafetyConfig;
fbSafety.abDriveReady[1] := fbAxis.astAxisStatus[1].bEnabled;
fbSafety.abDriveReady[2] := fbAxis.astAxisStatus[2].bEnabled;

(* Step 3 - Evaluate alarm conditions with current safety state *)
fbAlarm.EvaluateConditions();
(* TODO: wire safety to alarm *)
fbAlarm.stSafetyStatus := fbSafety.stSafetyStatus;
fbAlarm.bAnyAxisError := fbAxis.bAnyAxisError;
fbAlarm.bHomingError := fbHoming.bHomingError;

(* Step 4 - Determine mode based on safety + alarms *)
fbMode.Cyclic();
(* TODO: wire inputs to mode manager *)
fbMode.stSafetyStatus := fbSafety.stSafetyStatus;
fbMode.bAnyFaultActive := fbAlarm.bAnyFaultActive;
fbMode.bAllAxesReady := fbAxis.bAllAxesReady;
fbMode.bAllAxesHomed := fbHoming.bAllAxesHomed;
fbMode.eRequestedMode := fbCommand.eRequestedMode;
fbMode.bResetRequested := fbCommand.bResetRequested;

(* Step 5 - Parse and validate operator commands against current mode *)
fbCommand.Cyclic();
(* TODO: wire HMI command from test harness or HMI *)
fbCommand.eCurrentMode := fbMode.eCurrentMode;
fbCommand.stModePermits := fbMode.stModePermits;
fbCommand.stSafetyStatus := fbSafety.stSafetyStatus;
fbCommand.stHMICommand := fbTest.stHMICommand;  (* TestHarness or real HMI *)

(* Step 6 - Execute homing if in HOMING mode *)
fbHoming.Cyclic();
fbHoming.eCurrentMode := fbMode.eCurrentMode;
fbHoming.bStartHoming := fbCommand.bStartHoming;
fbHoming.bAbortHoming := fbCommand.bAbortHoming;
(* TODO: wire home switch signals from virtual or physical I/O *)
fbHoming.astAxisConfig := fbConfig.stMachineConfig.astAxisConfig;

(* Step 7 - Execute motion commands, safety always wins *)
fbAxis.Cyclic();
fbAxis.stModePermits := fbMode.stModePermits;
fbAxis.eCurrentMode := fbMode.eCurrentMode;
fbAxis.stCommand := fbCommand.stMotionCommand;
fbAxis.stSafetyStatus := fbSafety.stSafetyStatus;
fbAxis.astAxisConfig := fbConfig.stMachineConfig.astAxisConfig;

(* Step 8 - Finalize alarm states after all motion evaluated *)
fbAlarm.UpdateOutputs();
fbAlarm.bAckRequested := fbCommand.bAckRequested;
fbAlarm.nAckAlarmID := fbCommand.nAckAlarmID;
fbAlarm.bResetAllRequested := fbCommand.bResetAllRequested;

(* Step 9 - Log all pending trace events *)
fbTrace.Cyclic();

(* Step 10 - Aggregate all status into HMI data structure *)
fbHMI.Cyclic();
fbHMI.eCurrentMode := fbMode.eCurrentMode;
fbHMI.stModePermits := fbMode.stModePermits;
fbHMI.astAxisStatus := fbAxis.astAxisStatus;
fbHMI.stSafetyStatus := fbSafety.stSafetyStatus;
fbHMI.astActiveAlarms := fbAlarm.astActiveAlarms;
fbHMI.nActiveAlarmCount := fbAlarm.nActiveAlarmCount;
fbHMI.eHighestSeverity := fbAlarm.eHighestSeverity;
fbHMI.astRecentEvents := fbTrace.astRecentEvents;
fbHMI.eHomingState := fbHoming.eHomingState;
fbHMI.bSimulationMode := fbConfig.bSimulationMode;

(* Step 11 - Test harness runs last, only active in simulation *)
fbTest.Cyclic();
fbTest.eCurrentMode := fbMode.eCurrentMode;
fbTest.astAxisStatus := fbAxis.astAxisStatus;
fbTest.stSafetyStatus := fbSafety.stSafetyStatus;
fbTest.nActiveAlarmCount := fbAlarm.nActiveAlarmCount;
fbTest.bSimulationMode := fbConfig.bSimulationMode;

END_PROGRAM

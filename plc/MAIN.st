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
fbSafety.bSimulationMode := fbConfig.bSimulationMode;
fbSafety.stConfig := fbConfig.stMachineConfig.stSafetyConfig;
fbSafety.abDriveReady[1] := fbAxis.astAxisStatus[1].bEnabled;
fbSafety.abDriveReady[2] := fbAxis.astAxisStatus[2].bEnabled;
fbSafety.Cyclic();

(* Step 3 - Evaluate alarm conditions with current safety state *)
fbAlarm.stSafetyStatus := fbSafety.stSafetyStatus;
fbAlarm.bAnyAxisError := fbAxis.bAnyAxisError;
fbAlarm.bHomingError := fbHoming.bHomingError;
fbAlarm.bConfigInvalid := NOT fbConfig.bConfigValid;
fbAlarm.EvaluateConditions();

(* Step 4 - Determine mode based on safety + alarms *)
fbMode.stSafetyStatus := fbSafety.stSafetyStatus;
fbMode.bAnyFaultActive := fbAlarm.bAnyFaultActive;
fbMode.bAllAxesReady := fbAxis.bAllAxesReady;
fbMode.bAllAxesHomed := fbHoming.bAllAxesHomed;
fbMode.eRequestedMode := fbCommand.eRequestedMode;
fbMode.bResetRequested := fbCommand.bResetRequested;
fbMode.Cyclic();

(* Step 5 - Parse and validate operator commands against current mode *)
fbCommand.eCurrentMode := fbMode.eCurrentMode;
fbCommand.stModePermits := fbMode.stModePermits;
fbCommand.stSafetyStatus := fbSafety.stSafetyStatus;
fbCommand.stHMICommand := fbTest.stHMICommand;  (* TestHarness or real HMI *)
fbCommand.Cyclic();

(* Step 6 - Execute homing if in HOMING mode *)
fbHoming.eCurrentMode := fbMode.eCurrentMode;
fbHoming.bStartHoming := fbCommand.bStartHoming;
fbHoming.bAbortHoming := fbCommand.bAbortHoming;
fbHoming.astAxisConfig := fbConfig.stMachineConfig.astAxisConfig;
IF fbConfig.bSimulationMode THEN
    fbHoming.abHomeSwitchActive := GVL_VirtualIO.stVirtualIO.abHomeSwitch;
ELSE
    fbHoming.abHomeSwitchActive[1] := GVL_IO.bPhysHomeSwitch1;
    fbHoming.abHomeSwitchActive[2] := GVL_IO.bPhysHomeSwitch2;
END_IF
(* Link axis references and call cyclic *)
fbHoming(axis1Ref := fbAxis.axis1Ref, axis2Ref := fbAxis.axis2Ref);
fbHoming.Cyclic();

(* Step 7 - Execute motion commands, safety always wins *)
fbAxis.stModePermits := fbMode.stModePermits;
fbAxis.eCurrentMode := fbMode.eCurrentMode;
fbAxis.stCommand := fbCommand.stMotionCommand;
fbAxis.stSafetyStatus := fbSafety.stSafetyStatus;
fbAxis.astAxisConfig := fbConfig.stMachineConfig.astAxisConfig;
fbAxis.Cyclic();

(* Step 8 - Finalize alarm states after all motion evaluated *)
fbAlarm.bAckRequested := fbCommand.bAckRequested;
fbAlarm.nAckAlarmID := fbCommand.nAckAlarmID;
fbAlarm.bResetAllRequested := fbCommand.bResetAllRequested;
fbAlarm.UpdateOutputs();

(* Step 9 - Log all pending trace events *)
fbTrace.Cyclic();

(* Step 10 - Aggregate all status into HMI data structure *)
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
fbHMI.Cyclic();

(* Step 11 - Test harness runs last, only active in simulation *)
fbTest.eCurrentMode := fbMode.eCurrentMode;
fbTest.astAxisStatus := fbAxis.astAxisStatus;
fbTest.stSafetyStatus := fbSafety.stSafetyStatus;
fbTest.nActiveAlarmCount := fbAlarm.nActiveAlarmCount;
fbTest.bSimulationMode := fbConfig.bSimulationMode;
fbTest.Cyclic();

END_PROGRAM

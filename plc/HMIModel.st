FUNCTION_BLOCK FB_HMIModel
VAR_INPUT
    eCurrentMode        : E_MachineMode;
    stModePermits       : ST_ModePermits;
    astAxisStatus       : ARRAY[1..2] OF ST_AxisStatus;
    stSafetyStatus      : ST_SafetyStatus;
    astActiveAlarms     : ARRAY[1..32] OF ST_Alarm;
    nActiveAlarmCount   : UINT;
    eHighestSeverity    : E_AlarmSeverity;
    astRecentEvents     : ARRAY[1..20] OF ST_TraceEvent;
    eHomingState        : E_HomingState;
    bSimulationMode     : BOOL;
END_VAR

VAR_OUTPUT
    stHMIData       : ST_HMIData;
    stHMICommand    : ST_HMICommand;
END_VAR

VAR
    bDataStaleTimer : TON;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: Aggregate all status into stHMIData, increment cycle count *)
(* TODO: stHMIData.eCurrentMode := eCurrentMode *)
(* TODO: stHMIData.stModePermits := stModePermits *)
(* TODO: stHMIData.astAxisStatus := astAxisStatus *)
(* TODO: stHMIData.stSafetyStatus := stSafetyStatus *)
(* TODO: stHMIData.astActiveAlarms := astActiveAlarms *)
(* TODO: stHMIData.nActiveAlarmCount := nActiveAlarmCount *)
(* TODO: stHMIData.eHighestSeverity := eHighestSeverity *)
(* TODO: stHMIData.astRecentEvents := astRecentEvents *)
(* TODO: stHMIData.eHomingState := eHomingState *)
(* TODO: stHMIData.bSimulationMode := bSimulationMode *)
(* TODO: stHMIData.nCycleCount := stHMIData.nCycleCount + 1 *)
(* TODO: set stHMIData.bHMIDataStale based on bDataStaleTimer *)
END_METHOD

END_FUNCTION_BLOCK

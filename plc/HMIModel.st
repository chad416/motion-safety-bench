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

stHMIData.eCurrentMode := eCurrentMode;
stHMIData.stModePermits := stModePermits;
stHMIData.astAxisStatus := astAxisStatus;
stHMIData.stSafetyStatus := stSafetyStatus;
stHMIData.astActiveAlarms := astActiveAlarms;
stHMIData.nActiveAlarmCount := nActiveAlarmCount;
stHMIData.eHighestSeverity := eHighestSeverity;
stHMIData.astRecentEvents := astRecentEvents;
stHMIData.eHomingState := eHomingState;
stHMIData.bSimulationMode := bSimulationMode;

stHMIData.nCycleCount := stHMIData.nCycleCount + 1;

(* Simulated stale detection - always FALSE if cyclic is running *)
stHMIData.bHMIDataStale := FALSE;

END_METHOD

END_FUNCTION_BLOCK

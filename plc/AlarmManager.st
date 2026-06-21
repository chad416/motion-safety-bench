FUNCTION_BLOCK FB_AlarmManager
VAR_INPUT
    stSafetyStatus      : ST_SafetyStatus;
    bAnyAxisError       : BOOL;
    bHomingError        : BOOL;
    bConfigInvalid      : BOOL;
    bAckRequested       : BOOL;
    nAckAlarmID         : UINT;
    bResetAllRequested  : BOOL;
END_VAR

VAR_OUTPUT
    bAnyFaultActive     : BOOL;
    bAnyAlarmActive     : BOOL;
    nActiveAlarmCount   : UINT;
    eHighestSeverity    : E_AlarmSeverity;
    astActiveAlarms     : ARRAY[1..32] OF ST_Alarm;
END_VAR

VAR
    astAlarmBuffer      : ARRAY[1..32] OF ST_Alarm;
    astHistory          : ARRAY[1..200] OF ST_Alarm;
    nWriteIdx           : UINT;
    nHistoryIdx         : UINT;
END_VAR

(* ========== CONDITION EVALUATION ========== *)
METHOD EvaluateConditions
(* Method: EvaluateConditions — Purpose: Check all alarm source conditions, raise alarms as needed *)
(* TODO: IF NOT stSafetyStatus.bSafeToRun AND stSafetyStatus.bEStopActive THEN RaiseAlarm(1001, SEV_CRITICAL, 'E-stop active', 'SafetyManager', TRUE) *)
(* TODO: IF stSafetyStatus.bRelayDiscrepancy THEN RaiseAlarm(1002, SEV_CRITICAL, 'Safety relay discrepancy', 'SafetyManager', TRUE) *)
(* TODO: IF stSafetyStatus.bAnyLimitTripped THEN RaiseAlarm(1003, SEV_FAULT, 'Limit switch tripped', 'SafetyManager', TRUE) *)
(* TODO: IF bAnyAxisError THEN RaiseAlarm(2001, SEV_FAULT, 'Axis error', 'AxisManager', TRUE) *)
(* TODO: IF bHomingError THEN RaiseAlarm(3001, SEV_FAULT, 'Homing failed', 'HomingManager', TRUE) *)
END_METHOD

(* ========== OUTPUTS ========== *)
METHOD UpdateOutputs
(* Method: UpdateOutputs — Purpose: Update bAnyFaultActive, counts, highest severity *)
(* TODO: iterate astAlarmBuffer, count ACTIVE alarms, find highest severity *)
(* TODO: set bAnyFaultActive := any alarm with eSeverity >= SEV_FAULT is ACTIVE and unacknowledged *)
(* TODO: copy active alarms to astActiveAlarms output *)
END_METHOD

(* ========== RAISE ALARM ========== *)
METHOD RaiseAlarm
VAR_INPUT
    nID         : UINT;
    eSeverity   : E_AlarmSeverity;
    sMessage    : STRING(80);
    sSource     : STRING(40);
    bRequiresAck: BOOL;
END_VAR
(* Method: RaiseAlarm — Purpose: Add or update alarm in buffer with timestamp *)
(* TODO: check if alarm nID already active, if not find empty slot and populate *)
(* TODO: set tRaiseTime := NOW_DT(), eState := ALARM_ACTIVE *)
END_METHOD

(* ========== ACKNOWLEDGE ALARM ========== *)
METHOD AcknowledgeAlarm
VAR_INPUT
    nAlarmID : UINT;
END_VAR
(* Method: AcknowledgeAlarm — Purpose: Transition alarm from ACTIVE to ACKNOWLEDGED *)
(* TODO: find alarm by nID, if eState=ALARM_ACTIVE set eState:=ALARM_ACKNOWLEDGED, tAckTime:=NOW_DT() *)
END_METHOD

(* ========== RESET ALARM ========== *)
METHOD ResetAlarm
VAR_INPUT
    nAlarmID : UINT;
END_VAR
(* Method: ResetAlarm — Purpose: Clear alarm if condition is gone *)
(* TODO: find alarm by nID, if NOT bRequiresAck or already ACKNOWLEDGED, set eState:=ALARM_CLEARED *)
END_METHOD

(* ========== RESET ALL ALARMS ========== *)
METHOD ResetAllAlarms
(* Method: ResetAllAlarms — Purpose: Clear all clearable alarms *)
(* TODO: iterate buffer, call ResetAlarm on each *)
END_METHOD

END_FUNCTION_BLOCK

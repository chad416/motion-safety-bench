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

(* Safety Alarms *)
IF NOT stSafetyStatus.bSafeToRun THEN
    IF stSafetyStatus.bEStopActive THEN
        RaiseAlarm(1001, SEV_CRITICAL, 'E-stop active', 'SafetyManager', TRUE);
    END_IF
    IF stSafetyStatus.bRelayDiscrepancy THEN
        RaiseAlarm(1002, SEV_CRITICAL, 'Safety relay discrepancy', 'SafetyManager', TRUE);
    END_IF
    IF stSafetyStatus.abLimitPosActive[1] OR stSafetyStatus.abLimitNegActive[1] THEN
        RaiseAlarm(1003, SEV_FAULT, 'Axis 1 limit tripped', 'SafetyManager', TRUE);
    END_IF
    IF stSafetyStatus.abLimitPosActive[2] OR stSafetyStatus.abLimitNegActive[2] THEN
        RaiseAlarm(1004, SEV_FAULT, 'Axis 2 limit tripped', 'SafetyManager', TRUE);
    END_IF
END_IF

(* Motion Alarms *)
IF bAnyAxisError THEN
    RaiseAlarm(2001, SEV_FAULT, 'Axis drive error', 'AxisManager', TRUE);
END_IF

(* Homing Alarms *)
IF bHomingError THEN
    RaiseAlarm(3001, SEV_FAULT, 'Homing failed', 'HomingManager', TRUE);
END_IF

(* Config Alarms *)
IF bConfigInvalid THEN
    RaiseAlarm(7001, SEV_WARNING, 'Invalid configuration', 'ConfigPackage', TRUE);
END_IF

(* Handle Operator Requests *)
IF bAckRequested THEN
    AcknowledgeAlarm(nAckAlarmID);
END_IF

IF bResetAllRequested THEN
    ResetAllAlarms();
END_IF

END_METHOD

(* ========== OUTPUTS ========== *)
METHOD UpdateOutputs
VAR
    i : UINT;
    nActive : UINT := 0;
    eMaxSev : E_AlarmSeverity := SEV_INFO;
    bFault : BOOL := FALSE;
END_VAR
(* Method: UpdateOutputs — Purpose: Update bAnyFaultActive, counts, highest severity *)

FOR i := 1 TO 32 DO
    IF astAlarmBuffer[i].eState <> ALARM_INACTIVE AND astAlarmBuffer[i].eState <> ALARM_CLEARED THEN
        nActive := nActive + 1;
        IF astAlarmBuffer[i].eSeverity > eMaxSev THEN
            eMaxSev := astAlarmBuffer[i].eSeverity;
        END_IF
        IF astAlarmBuffer[i].eSeverity >= SEV_FAULT THEN
            bFault := TRUE;
        END_IF
    END_IF
    astActiveAlarms[i] := astAlarmBuffer[i];
END_FOR

nActiveAlarmCount := nActive;
eHighestSeverity := eMaxSev;
bAnyFaultActive := bFault;
bAnyAlarmActive := (nActive > 0);

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
VAR
    i : UINT;
    nEmptySlot : UINT := 0;
END_VAR
(* Method: RaiseAlarm — Purpose: Add or update alarm in buffer with timestamp *)

FOR i := 1 TO 32 DO
    IF astAlarmBuffer[i].nID = nID THEN
        (* Already active or in buffer, don't re-raise if active *)
        IF astAlarmBuffer[i].eState = ALARM_INACTIVE OR astAlarmBuffer[i].eState = ALARM_CLEARED THEN
            astAlarmBuffer[i].eState := ALARM_ACTIVE;
            astAlarmBuffer[i].eSeverity := eSeverity;
            astAlarmBuffer[i].sMessage := sMessage;
            astAlarmBuffer[i].sSource := sSource;
            astAlarmBuffer[i].bRequiresAck := bRequiresAck;
            (* tRaiseTime would be set here if DT available *)
        END_IF
        RETURN;
    END_IF
    IF nEmptySlot = 0 AND (astAlarmBuffer[i].eState = ALARM_INACTIVE OR astAlarmBuffer[i].eState = ALARM_CLEARED) THEN
        nEmptySlot := i;
    END_IF
END_FOR

IF nEmptySlot <> 0 THEN
    astAlarmBuffer[nEmptySlot].nID := nID;
    astAlarmBuffer[nEmptySlot].eSeverity := eSeverity;
    astAlarmBuffer[nEmptySlot].eState := ALARM_ACTIVE;
    astAlarmBuffer[nEmptySlot].sMessage := sMessage;
    astAlarmBuffer[nEmptySlot].sSource := sSource;
    astAlarmBuffer[nEmptySlot].bRequiresAck := bRequiresAck;
END_IF

END_METHOD

(* ========== ACKNOWLEDGE ALARM ========== *)
METHOD AcknowledgeAlarm
VAR_INPUT
    nAlarmID : UINT;
END_VAR
VAR
    i : UINT;
END_VAR
(* Method: AcknowledgeAlarm — Purpose: Transition alarm from ACTIVE to ACKNOWLEDGED *)
FOR i := 1 TO 32 DO
    IF astAlarmBuffer[i].nID = nAlarmID AND astAlarmBuffer[i].eState = ALARM_ACTIVE THEN
        astAlarmBuffer[i].eState := ALARM_ACKNOWLEDGED;
        RETURN;
    END_IF
END_FOR
END_METHOD

(* ========== RESET ALARM ========== *)
METHOD ResetAlarm
VAR_INPUT
    nAlarmID : UINT;
END_VAR
VAR
    i : UINT;
END_VAR
(* Method: ResetAlarm — Purpose: Clear alarm if condition is gone *)
FOR i := 1 TO 32 DO
    IF astAlarmBuffer[i].nID = nAlarmID THEN
        IF NOT astAlarmBuffer[i].bRequiresAck OR astAlarmBuffer[i].eState = ALARM_ACKNOWLEDGED THEN
            astAlarmBuffer[i].eState := ALARM_CLEARED;
            astAlarmBuffer[i].nID := 0; (* Free slot *)
        END_IF
        RETURN;
    END_IF
END_FOR
END_METHOD

(* ========== RESET ALL ALARMS ========== *)
METHOD ResetAllAlarms
VAR
    i : UINT;
END_VAR
(* Method: ResetAllAlarms — Purpose: Clear all clearable alarms *)
FOR i := 1 TO 32 DO
    IF astAlarmBuffer[i].nID <> 0 THEN
        ResetAlarm(astAlarmBuffer[i].nID);
    END_IF
END_FOR
END_METHOD

END_FUNCTION_BLOCK

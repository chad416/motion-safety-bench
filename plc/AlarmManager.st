FUNCTION_BLOCK FB_AlarmManager
VAR_INPUT
    stSafetyStatus : ST_SafetyStatus;
    bAnyAxisError : BOOL;
    bHomingError : BOOL;
    bConfigInvalid : BOOL;
    bCommandRejected : BOOL;
    bAckRequested : BOOL;
    nAckAlarmID : UINT;
    bResetAllRequested : BOOL;
END_VAR
VAR_OUTPUT
    bAnyFaultActive : BOOL;
    bAnyAlarmActive : BOOL;
    nActiveAlarmCount : UINT;
    eHighestSeverity : E_AlarmSeverity;
    astActiveAlarms : ARRAY[1..32] OF ST_Alarm;
    astAlarmHistory : ARRAY[1..200] OF ST_Alarm;
    nHistoryCount : UINT;
END_VAR
VAR
    astAlarmBuffer : ARRAY[1..32] OF ST_Alarm;
    abCondition : ARRAY[1..10] OF BOOL;
    anAlarmID : ARRAY[1..10] OF UINT :=
        [1001, 1002, 1003, 1004, 1005, 1006, 1007, 2001, 3001, 5001];
    aeSeverity : ARRAY[1..10] OF E_AlarmSeverity :=
        [SEV_CRITICAL, SEV_CRITICAL, SEV_FAULT, SEV_CRITICAL, SEV_CRITICAL,
         SEV_CRITICAL, SEV_CRITICAL, SEV_FAULT, SEV_FAULT, SEV_WARNING];
    nIndex : UINT;
    nOutputIndex : UINT;
    nHistoryWriteIndex : UINT;
    bWasActive : BOOL;
END_VAR

abCondition[1] := stSafetyStatus.bEStopActive;
abCondition[2] := stSafetyStatus.bRelayDiscrepancy;
abCondition[3] := stSafetyStatus.bAnyLimitTripped;
abCondition[4] := stSafetyStatus.bGuardDoorOpen;
abCondition[5] := stSafetyStatus.bSTOActive OR stSafetyStatus.bDriveInhibit;
abCondition[6] := NOT stSafetyStatus.bNetworkHealthy;
abCondition[7] := NOT stSafetyStatus.bWatchdogHealthy;
abCondition[8] := bAnyAxisError;
abCondition[9] := bHomingError;
abCondition[10] := bConfigInvalid OR bCommandRejected;

FOR nIndex := 1 TO 10 DO
    astAlarmBuffer[nIndex].nID := anAlarmID[nIndex];
    astAlarmBuffer[nIndex].eSeverity := aeSeverity[nIndex];
    astAlarmBuffer[nIndex].bRequiresAck := aeSeverity[nIndex] >= SEV_FAULT;
    astAlarmBuffer[nIndex].bSelfClearing :=
        (aeSeverity[nIndex] < SEV_FAULT) AND (nIndex <> 10);

    CASE nIndex OF
        1:
            astAlarmBuffer[nIndex].sMessage := 'Emergency-stop chain is open';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        2:
            astAlarmBuffer[nIndex].sMessage := 'Safety relay feedback discrepancy';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        3:
            astAlarmBuffer[nIndex].sMessage := 'Hardware limit switch activated';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        4:
            astAlarmBuffer[nIndex].sMessage := 'Guard door or safety gate is open';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        5:
            astAlarmBuffer[nIndex].sMessage := 'STO active or drive inhibit requested';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        6:
            astAlarmBuffer[nIndex].sMessage := 'EtherCAT or network health lost';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        7:
            astAlarmBuffer[nIndex].sMessage := 'PLC watchdog heartbeat timed out';
            astAlarmBuffer[nIndex].sSource := 'SafetyManager';
        8:
            astAlarmBuffer[nIndex].sMessage := 'Axis reported drive, feedback or following error';
            astAlarmBuffer[nIndex].sSource := 'AxisManager';
        9:
            astAlarmBuffer[nIndex].sMessage := 'Homing sequence failed';
            astAlarmBuffer[nIndex].sSource := 'HomingManager';
        10:
            astAlarmBuffer[nIndex].sMessage := 'Configuration or command validation warning';
            astAlarmBuffer[nIndex].sSource := 'CommandParser';
    END_CASE

    bWasActive := (astAlarmBuffer[nIndex].eState = ALARM_ACTIVE) OR
        (astAlarmBuffer[nIndex].eState = ALARM_ACKNOWLEDGED);

    IF abCondition[nIndex] THEN
        IF NOT bWasActive THEN
            astAlarmBuffer[nIndex].eState := ALARM_ACTIVE;
            nHistoryWriteIndex := nHistoryWriteIndex + 1;
            IF nHistoryWriteIndex > cMAX_ALARM_HISTORY THEN
                nHistoryWriteIndex := 1;
            END_IF
            astAlarmHistory[nHistoryWriteIndex] := astAlarmBuffer[nIndex];
            IF nHistoryCount < cMAX_ALARM_HISTORY THEN
                nHistoryCount := nHistoryCount + 1;
            END_IF
        END_IF

        IF bAckRequested AND
           ((nAckAlarmID = astAlarmBuffer[nIndex].nID) OR (nAckAlarmID = 0)) THEN
            astAlarmBuffer[nIndex].eState := ALARM_ACKNOWLEDGED;
        END_IF
    ELSE
        IF astAlarmBuffer[nIndex].bSelfClearing OR
           (astAlarmBuffer[nIndex].eState = ALARM_ACKNOWLEDGED) OR
           bResetAllRequested THEN
            astAlarmBuffer[nIndex].eState := ALARM_INACTIVE;
        END_IF
    END_IF

    IF bResetAllRequested AND (NOT abCondition[nIndex]) THEN
        astAlarmBuffer[nIndex].eState := ALARM_INACTIVE;
    END_IF
END_FOR

nActiveAlarmCount := 0;
nOutputIndex := 0;
bAnyFaultActive := FALSE;
bAnyAlarmActive := FALSE;
eHighestSeverity := SEV_INFO;

FOR nIndex := 1 TO cMAX_ALARMS DO
    astActiveAlarms[nIndex].eState := ALARM_INACTIVE;
    IF (astAlarmBuffer[nIndex].eState = ALARM_ACTIVE) OR
       (astAlarmBuffer[nIndex].eState = ALARM_ACKNOWLEDGED) THEN
        bAnyAlarmActive := TRUE;
        nActiveAlarmCount := nActiveAlarmCount + 1;
        nOutputIndex := nOutputIndex + 1;
        astActiveAlarms[nOutputIndex] := astAlarmBuffer[nIndex];

        IF astAlarmBuffer[nIndex].eSeverity > eHighestSeverity THEN
            eHighestSeverity := astAlarmBuffer[nIndex].eSeverity;
        END_IF
        IF astAlarmBuffer[nIndex].eSeverity >= SEV_FAULT THEN
            bAnyFaultActive := TRUE;
        END_IF
    END_IF
END_FOR

END_FUNCTION_BLOCK

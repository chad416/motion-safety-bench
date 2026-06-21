FUNCTION_BLOCK FB_CommandParser
VAR_INPUT
    stHMICommand    : ST_HMICommand;
    eCurrentMode    : E_MachineMode;
    stModePermits   : ST_ModePermits;
    stSafetyStatus  : ST_SafetyStatus;
END_VAR

VAR_OUTPUT
    eRequestedMode      : E_MachineMode;
    stMotionCommand     : ST_MotionCommand;
    bStartHoming        : BOOL;
    bAbortHoming        : BOOL;
    bAckRequested       : BOOL;
    nAckAlarmID         : UINT;
    bResetRequested     : BOOL;
    bResetAllRequested  : BOOL;
    eLastCommandStatus  : E_CommandStatus;
    sLastCommandError   : STRING(120);
END_VAR

VAR
    eProcessingState    : E_CommandStatus;
    rtrigExecute        : R_TRIG;
    nCommandCounter     : UDINT;
    nRejectedCounter    : UDINT;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: Detect rising edge on bExecute, validate, route command *)

rtrigExecute(CLK := stHMICommand.bExecute);

IF rtrigExecute.Q THEN
    nCommandCounter := nCommandCounter + 1;
    IF ValidateCommand() THEN
        eLastCommandStatus := CMDSTAT_EXECUTING;
        sLastCommandError := '';

        CASE stHMICommand.eCommandType OF
            CMD_MODE_REQUEST:
                eRequestedMode := stHMICommand.eTargetMode;

            CMD_JOG_POSITIVE, CMD_JOG_NEGATIVE, CMD_MOVE_ABSOLUTE, CMD_MOVE_RELATIVE, CMD_STOP:
                stMotionCommand.eType := stHMICommand.eCommandType;
                stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
                stMotionCommand.fTargetPosition := stHMICommand.fValue1;
                stMotionCommand.fDistance := stHMICommand.fValue1;
                stMotionCommand.fVelocity := stHMICommand.fValue2;
                stMotionCommand.bExecute := TRUE;

            CMD_HOME:
                bStartHoming := TRUE;

            CMD_RESET:
                bResetRequested := TRUE;

            CMD_ACK_ALARM:
                bAckRequested := TRUE;
                nAckAlarmID := stHMICommand.nAlarmID;

            CMD_RESET_ALL_ALARMS:
                bResetAllRequested := TRUE;
        END_CASE
    ELSE
        eLastCommandStatus := CMDSTAT_ERROR;
        nRejectedCounter := nRejectedCounter + 1;
    END_IF
ELSE
    (* Reset single-cycle triggers *)
    bStartHoming := FALSE;
    bResetRequested := FALSE;
    bAckRequested := FALSE;
    bResetAllRequested := FALSE;
    IF stMotionCommand.eType <> CMD_JOG_POSITIVE AND stMotionCommand.eType <> CMD_JOG_NEGATIVE THEN
        stMotionCommand.bExecute := FALSE;
    ELSE
        (* Keep jog active if bExecute is still true in the input struct *)
        stMotionCommand.bExecute := stHMICommand.bExecute;
    END_IF
END_IF

END_METHOD

METHOD ValidateCommand : BOOL
(* Method: ValidateCommand - Purpose: Check if command allowed in current mode and safety state *)

ValidateCommand := FALSE;

CASE stHMICommand.eCommandType OF
    CMD_MODE_REQUEST:
        IF stModePermits.bAllowModeChange THEN
            ValidateCommand := TRUE;
        ELSE
            sLastCommandError := 'Mode change not permitted';
        END_IF

    CMD_JOG_POSITIVE, CMD_JOG_NEGATIVE:
        IF stModePermits.bAllowJog AND stSafetyStatus.bSafeToRun THEN
            ValidateCommand := TRUE;
        ELSE
            sLastCommandError := 'Jog not permitted or safety not OK';
        END_IF

    CMD_MOVE_ABSOLUTE, CMD_MOVE_RELATIVE:
        IF stModePermits.bAllowMotion AND stSafetyStatus.bSafeToRun THEN
            ValidateCommand := TRUE;
        ELSE
            sLastCommandError := 'Motion not permitted or safety not OK';
        END_IF

    CMD_STOP:
        ValidateCommand := TRUE;

    CMD_HOME:
        IF stModePermits.bAllowHoming THEN
            ValidateCommand := TRUE;
        ELSE
            sLastCommandError := 'Homing not permitted';
        END_IF

    CMD_RESET, CMD_ACK_ALARM, CMD_RESET_ALL_ALARMS:
        IF stModePermits.bAllowAlarmReset THEN
            ValidateCommand := TRUE;
        ELSE
             sLastCommandError := 'Reset not permitted';
        END_IF

    CMD_NONE:
        ValidateCommand := TRUE;
END_CASE

END_METHOD

END_FUNCTION_BLOCK

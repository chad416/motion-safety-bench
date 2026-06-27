FUNCTION_BLOCK FB_CommandParser
VAR_INPUT
    stHMICommand : ST_HMICommand;
    eCurrentMode : E_MachineMode;
    stModePermits : ST_ModePermits;
    stSafetyStatus : ST_SafetyStatus;
END_VAR
VAR_OUTPUT
    eRequestedMode : E_MachineMode;
    stMotionCommand : ST_MotionCommand;
    bStartHoming : BOOL;
    bAbortHoming : BOOL;
    bAckRequested : BOOL;
    nAckAlarmID : UINT;
    bResetRequested : BOOL;
    bResetAllRequested : BOOL;
    eLastCommandStatus : E_CommandStatus;
    sLastCommandError : STRING(120);
    nCommandCounter : UDINT;
    nRejectedCounter : UDINT;
END_VAR
VAR
    rtrigExecute : R_TRIG;
    bCommandAllowed : BOOL;
END_VAR

rtrigExecute(CLK := stHMICommand.bExecute);

(* Command outputs are pulses except jog, whose Execute level is intentional. *)
bStartHoming := FALSE;
bAbortHoming := FALSE;
bAckRequested := FALSE;
bResetRequested := FALSE;
bResetAllRequested := FALSE;
stMotionCommand.bExecute := FALSE;
stMotionCommand.bJogPositive := FALSE;
stMotionCommand.bJogNegative := FALSE;

IF (stHMICommand.eCommandType = CMD_JOG_POSITIVE) AND stHMICommand.bExecute AND
   stModePermits.bAllowJog AND stSafetyStatus.bSafeToRun THEN
    stMotionCommand.eType := CMD_JOG_POSITIVE;
    stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
    stMotionCommand.fVelocity := stHMICommand.fValue1;
    stMotionCommand.bJogPositive := TRUE;
    stMotionCommand.bExecute := TRUE;
ELSIF (stHMICommand.eCommandType = CMD_JOG_NEGATIVE) AND stHMICommand.bExecute AND
      stModePermits.bAllowJog AND stSafetyStatus.bSafeToRun THEN
    stMotionCommand.eType := CMD_JOG_NEGATIVE;
    stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
    stMotionCommand.fVelocity := stHMICommand.fValue1;
    stMotionCommand.bJogNegative := TRUE;
    stMotionCommand.bExecute := TRUE;
END_IF

IF rtrigExecute.Q THEN
    nCommandCounter := nCommandCounter + 1;
    bCommandAllowed := TRUE;
    sLastCommandError := '';

    IF (stHMICommand.nAxisIndex > cMAX_AXES) AND
       (stHMICommand.eCommandType >= CMD_JOG_POSITIVE) AND
       (stHMICommand.eCommandType <= CMD_STOP) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Axis index is outside supported range';
    ELSIF ((stHMICommand.eCommandType = CMD_MOVE_ABSOLUTE) OR
           (stHMICommand.eCommandType = CMD_MOVE_RELATIVE) OR
           (stHMICommand.eCommandType = CMD_MOVE_VELOCITY) OR
           (stHMICommand.eCommandType = CMD_JOG_POSITIVE) OR
           (stHMICommand.eCommandType = CMD_JOG_NEGATIVE)) AND
          (NOT stSafetyStatus.bSafeToRun) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Motion command rejected: safety chain not healthy';
    ELSIF ((stHMICommand.eCommandType = CMD_MOVE_ABSOLUTE) OR
           (stHMICommand.eCommandType = CMD_MOVE_RELATIVE) OR
           (stHMICommand.eCommandType = CMD_MOVE_VELOCITY)) AND
          (NOT stModePermits.bAllowMotion) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Move command is not permitted in current mode';
    ELSIF ((stHMICommand.eCommandType = CMD_JOG_POSITIVE) OR
           (stHMICommand.eCommandType = CMD_JOG_NEGATIVE)) AND
          (NOT stModePermits.bAllowJog) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Jog command is not permitted in current mode';
    ELSIF (stHMICommand.eCommandType = CMD_HOME) AND
          (NOT stModePermits.bAllowHoming) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Homing is not permitted in current mode';
    ELSIF (stHMICommand.eCommandType = CMD_MODE_REQUEST) AND
          (NOT stModePermits.bAllowModeChange) THEN
        bCommandAllowed := FALSE;
        sLastCommandError := 'Mode change is not permitted';
    END_IF

    IF bCommandAllowed THEN
        eLastCommandStatus := CMDSTAT_DONE;
        CASE stHMICommand.eCommandType OF
            CMD_MODE_REQUEST:
                eRequestedMode := stHMICommand.eTargetMode;
            CMD_MOVE_ABSOLUTE:
                stMotionCommand.eType := CMD_MOVE_ABSOLUTE;
                stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
                stMotionCommand.fTargetPosition := stHMICommand.fValue1;
                stMotionCommand.fVelocity := stHMICommand.fValue2;
                stMotionCommand.bExecute := TRUE;
            CMD_MOVE_RELATIVE:
                stMotionCommand.eType := CMD_MOVE_RELATIVE;
                stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
                stMotionCommand.fDistance := stHMICommand.fValue1;
                stMotionCommand.fVelocity := stHMICommand.fValue2;
                stMotionCommand.bExecute := TRUE;
            CMD_MOVE_VELOCITY:
                stMotionCommand.eType := CMD_MOVE_VELOCITY;
                stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
                stMotionCommand.fVelocity := stHMICommand.fValue1;
                stMotionCommand.bExecute := TRUE;
            CMD_STOP:
                stMotionCommand.eType := CMD_STOP;
                stMotionCommand.nAxisIndex := stHMICommand.nAxisIndex;
                stMotionCommand.bExecute := TRUE;
            CMD_HOME:
                bStartHoming := TRUE;
            CMD_RESET:
                (* A reset establishes a deterministic INIT request. Retaining
                   an older HOMING/AUTO request can cause an unintended mode
                   transition immediately after the fault clears. *)
                eRequestedMode := MODE_INIT;
                bResetRequested := TRUE;
            CMD_ACK_ALARM:
                bAckRequested := TRUE;
                nAckAlarmID := stHMICommand.nAlarmID;
            CMD_RESET_ALL_ALARMS:
                bResetAllRequested := TRUE;
            CMD_NONE:
                eLastCommandStatus := CMDSTAT_IDLE;
        END_CASE
    ELSE
        eLastCommandStatus := CMDSTAT_ERROR;
        nRejectedCounter := nRejectedCounter + 1;
    END_IF
END_IF

END_FUNCTION_BLOCK

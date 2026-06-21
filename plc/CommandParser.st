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
(* TODO: rtrigExecute(CLK := stHMICommand.bExecute) *)
(* TODO: IF rtrigExecute.Q THEN ValidateCommand, if valid route to output *)
(* TODO: Route CMD_MODE_REQUEST -> eRequestedMode, CMD_JOG_POSITIVE/NEGATIVE -> stMotionCommand *)
(* TODO: Route CMD_MOVE_ABSOLUTE/RELATIVE -> stMotionCommand, CMD_HOME -> bStartHoming *)
(* TODO: Route CMD_RESET -> bResetRequested, CMD_ACK_ALARM -> bAckRequested + nAckAlarmID *)
END_METHOD

METHOD ValidateCommand : BOOL
(* Method: ValidateCommand - Purpose: Check if command allowed in current mode and safety state *)
(* TODO: CMD_MOVE_ABSOLUTE/RELATIVE: require stModePermits.bAllowMotion *)
(* TODO: CMD_JOG: require stModePermits.bAllowJog *)
(* TODO: CMD_HOME: require stModePermits.bAllowHoming *)
(* TODO: CMD_MODE_REQUEST AUTO: require stModePermits.bAllowAutoStart *)
(* TODO: reject motion commands when stSafetyStatus.bSafeToRun = FALSE *)
(* TODO: if not permitted: sLastCommandError := 'Command not permitted in current mode' *)
END_METHOD

END_FUNCTION_BLOCK

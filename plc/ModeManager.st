FUNCTION_BLOCK FB_ModeManager
VAR_INPUT
    stSafetyStatus      : ST_SafetyStatus;
    bAnyFaultActive     : BOOL;
    bAllAxesReady       : BOOL;
    bAllAxesHomed       : BOOL;
    eRequestedMode      : E_MachineMode;
    bResetRequested     : BOOL;
END_VAR

VAR_OUTPUT
    eCurrentMode            : E_MachineMode;
    ePreviousMode           : E_MachineMode;
    bModeTransitionActive   : BOOL;
    stModePermits           : ST_ModePermits;
END_VAR

VAR
    eInternalMode       : E_MachineMode;
    tonInitTimeout      : TON;
    tonHomingTimeout    : TON;
    bTransitionValid    : BOOL;
    rtrigModeRequest    : R_TRIG;
    rtrigResetRequest   : R_TRIG;
END_VAR

(* ========== CYCLIC PROCESSING ========== *)
METHOD Cyclic
(* Method: Cyclic — Purpose: Evaluate state machine, apply safety override, update permits *)

rtrigModeRequest(CLK := (eRequestedMode <> MODE_OFF AND eRequestedMode <> eInternalMode));
rtrigResetRequest(CLK := bResetRequested);

(* ========== SAFETY OVERRIDE ========== *)
IF NOT stSafetyStatus.bSafeToRun AND eInternalMode <> MODE_OFF AND eInternalMode <> MODE_FAULT THEN
    ePreviousMode := eInternalMode;
    eInternalMode := MODE_FAULT;
END_IF

(* ========== FAULT LATCH ========== *)
IF bAnyFaultActive AND eInternalMode <> MODE_FAULT AND eInternalMode <> MODE_OFF AND eInternalMode <> MODE_RESET THEN
    ePreviousMode := eInternalMode;
    eInternalMode := MODE_FAULT;
END_IF

(* ========== STATE MACHINE ========== *)
CASE eInternalMode OF
    MODE_OFF:
        IF rtrigModeRequest.Q AND eRequestedMode = MODE_INIT AND stSafetyStatus.bSafeToRun THEN
            ePreviousMode := MODE_OFF;
            eInternalMode := MODE_INIT;
        END_IF

    MODE_INIT:
        tonInitTimeout(IN := TRUE, PT := T#10S);
        IF bAllAxesReady AND NOT bAnyFaultActive THEN
            (* Stay in INIT, wait for Homing request or Auto/Manual if already homed *)
            IF rtrigModeRequest.Q AND ValidateTransition(MODE_INIT, eRequestedMode) THEN
                ePreviousMode := MODE_INIT;
                eInternalMode := eRequestedMode;
            END_IF
        ELSIF tonInitTimeout.Q THEN
            ePreviousMode := MODE_INIT;
            eInternalMode := MODE_FAULT;
        END_IF

    MODE_HOMING:
        tonHomingTimeout(IN := TRUE, PT := T#60S);
        IF bAllAxesHomed THEN
            tonHomingTimeout(IN := FALSE);
            ePreviousMode := MODE_HOMING;
            eInternalMode := MODE_MANUAL_JOG;
        ELSIF tonHomingTimeout.Q OR bAnyFaultActive THEN
            tonHomingTimeout(IN := FALSE);
            ePreviousMode := MODE_HOMING;
            eInternalMode := MODE_FAULT;
        END_IF

    MODE_MANUAL_JOG:
        IF rtrigModeRequest.Q AND ValidateTransition(MODE_MANUAL_JOG, eRequestedMode) THEN
            IF eRequestedMode = MODE_AUTO AND NOT bAllAxesHomed THEN
                (* Reject - need homing *)
            ELSE
                ePreviousMode := MODE_MANUAL_JOG;
                eInternalMode := eRequestedMode;
            END_IF
        END_IF

    MODE_AUTO:
        IF rtrigModeRequest.Q AND eRequestedMode = MODE_MANUAL_JOG THEN
            ePreviousMode := MODE_AUTO;
            eInternalMode := MODE_MANUAL_JOG;
        END_IF

    MODE_FAULT:
        IF rtrigResetRequest.Q AND stSafetyStatus.bSafeToRun THEN
            ePreviousMode := MODE_FAULT;
            eInternalMode := MODE_RESET;
        END_IF

    MODE_RESET:
        IF NOT bAnyFaultActive THEN
            ePreviousMode := MODE_RESET;
            eInternalMode := MODE_INIT;
        ELSIF rtrigModeRequest.Q THEN
             (* Allow forcing back to FAULT or OFF if needed *)
        END_IF
END_CASE

eCurrentMode := eInternalMode;
UpdatePermits();
END_METHOD

(* ========== TRANSITION VALIDATION ========== *)
METHOD ValidateTransition : BOOL
VAR_INPUT
    eFrom : E_MachineMode;
    eTo   : E_MachineMode;
END_VAR
(* Method: ValidateTransition — Purpose: Return TRUE if transition is valid per state table *)
CASE eFrom OF
    MODE_OFF:
        ValidateTransition := (eTo = MODE_INIT);
    MODE_INIT:
        ValidateTransition := (eTo = MODE_HOMING OR eTo = MODE_OFF);
    MODE_HOMING:
        ValidateTransition := (eTo = MODE_MANUAL_JOG OR eTo = MODE_FAULT);
    MODE_MANUAL_JOG:
        ValidateTransition := (eTo = MODE_AUTO OR eTo = MODE_HOMING OR eTo = MODE_OFF);
    MODE_AUTO:
        ValidateTransition := (eTo = MODE_MANUAL_JOG OR eTo = MODE_OFF);
    MODE_FAULT:
        ValidateTransition := (eTo = MODE_RESET OR eTo = MODE_OFF);
    MODE_RESET:
        ValidateTransition := (eTo = MODE_INIT OR eTo = MODE_FAULT);
END_CASE
END_METHOD

(* ========== MODE PERMITS ========== *)
METHOD UpdatePermits
(* Method: UpdatePermits — Purpose: Set stModePermits fields based on eCurrentMode *)
stModePermits.bAllowMotion := FALSE;
stModePermits.bAllowJog := FALSE;
stModePermits.bAllowHoming := FALSE;
stModePermits.bAllowAutoStart := FALSE;
stModePermits.bAllowModeChange := TRUE;
stModePermits.bAllowConfigEdit := FALSE;
stModePermits.bAllowAlarmReset := FALSE;

CASE eInternalMode OF
    MODE_OFF:
        stModePermits.bAllowConfigEdit := TRUE;
    MODE_INIT:
        (* Init permits *)
    MODE_HOMING:
        stModePermits.bAllowHoming := TRUE;
    MODE_MANUAL_JOG:
        stModePermits.bAllowMotion := TRUE;
        stModePermits.bAllowJog := TRUE;
        stModePermits.bAllowHoming := TRUE;
        stModePermits.bAllowAutoStart := TRUE;
    MODE_AUTO:
        stModePermits.bAllowMotion := TRUE;
    MODE_FAULT:
        stModePermits.bAllowAlarmReset := TRUE;
    MODE_RESET:
        stModePermits.bAllowAlarmReset := TRUE;
END_CASE
END_METHOD

END_FUNCTION_BLOCK

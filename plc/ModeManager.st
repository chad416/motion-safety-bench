FUNCTION_BLOCK FB_ModeManager
VAR_INPUT
    stSafetyStatus : ST_SafetyStatus;
    bAnyFaultActive : BOOL;
    bAllAxesReady : BOOL;
    bAllAxesHomed : BOOL;
    bHomingComplete : BOOL;
    bHomingError : BOOL;
    eRequestedMode : E_MachineMode;
    bResetRequested : BOOL;
    stTimingConfig : ST_TimingConfig;
END_VAR
VAR_OUTPUT
    eCurrentMode : E_MachineMode;
    ePreviousMode : E_MachineMode;
    bModeTransitionActive : BOOL;
    stModePermits : ST_ModePermits;
    nTransitionCounter : UDINT;
END_VAR
VAR
    eInternalMode : E_MachineMode := MODE_OFF;
    tonInitTimeout : TON;
    tonHomingTimeout : TON;
    tonResetSettle : TON;
    rtrigReset : R_TRIG;
    eLastRequestedMode : E_MachineMode;
    bRequestChanged : BOOL;
    eNextMode : E_MachineMode;
END_VAR

rtrigReset(CLK := bResetRequested);
bRequestChanged := eRequestedMode <> eLastRequestedMode;
IF bRequestChanged THEN
    eLastRequestedMode := eRequestedMode;
END_IF

eNextMode := eInternalMode;
bModeTransitionActive := FALSE;

(* Safety and critical faults always override operator requests. *)
IF ((NOT stSafetyStatus.bSafeToRun) OR bAnyFaultActive OR bHomingError) AND
   (eInternalMode <> MODE_OFF) AND (eInternalMode <> MODE_FAULT) AND
   (eInternalMode <> MODE_RESET) THEN
    eNextMode := MODE_FAULT;
END_IF

CASE eInternalMode OF
    MODE_OFF:
        IF stSafetyStatus.bSafeToRun AND (NOT bAnyFaultActive) AND
           ((eRequestedMode = MODE_INIT) OR (eRequestedMode = MODE_HOMING) OR
            (eRequestedMode = MODE_MANUAL_JOG) OR (eRequestedMode = MODE_AUTO)) THEN
            eNextMode := MODE_INIT;
        END_IF

    MODE_INIT:
        tonInitTimeout(IN := NOT bAllAxesReady, PT := stTimingConfig.tInitTimeout);
        IF tonInitTimeout.Q THEN
            eNextMode := MODE_FAULT;
        ELSIF bAllAxesReady AND (eRequestedMode = MODE_HOMING) THEN
            eNextMode := MODE_HOMING;
        ELSIF bAllAxesReady AND bAllAxesHomed AND
              (eRequestedMode = MODE_MANUAL_JOG) THEN
            eNextMode := MODE_MANUAL_JOG;
        END_IF

    MODE_HOMING:
        tonHomingTimeout(IN := NOT bHomingComplete, PT := stTimingConfig.tHomingTimeout);
        IF bHomingError OR tonHomingTimeout.Q THEN
            eNextMode := MODE_FAULT;
        ELSIF bHomingComplete AND bAllAxesHomed THEN
            eNextMode := MODE_MANUAL_JOG;
        END_IF

    MODE_MANUAL_JOG:
        IF bRequestChanged AND (eRequestedMode = MODE_HOMING) THEN
            eNextMode := MODE_HOMING;
        ELSIF bRequestChanged AND (eRequestedMode = MODE_AUTO) AND bAllAxesHomed THEN
            eNextMode := MODE_AUTO;
        ELSIF bRequestChanged AND (eRequestedMode = MODE_OFF) THEN
            eNextMode := MODE_OFF;
        END_IF

    MODE_AUTO:
        IF bRequestChanged AND (eRequestedMode = MODE_MANUAL_JOG) THEN
            eNextMode := MODE_MANUAL_JOG;
        ELSIF bRequestChanged AND (eRequestedMode = MODE_OFF) THEN
            eNextMode := MODE_OFF;
        END_IF

    MODE_FAULT:
        IF rtrigReset.Q AND stSafetyStatus.bSafeToRun THEN
            eNextMode := MODE_RESET;
        END_IF

    MODE_RESET:
        tonResetSettle(IN := TRUE, PT := T#500MS);
        IF NOT stSafetyStatus.bSafeToRun THEN
            eNextMode := MODE_FAULT;
        ELSIF tonResetSettle.Q AND (NOT bAnyFaultActive) THEN
            eNextMode := MODE_INIT;
        END_IF
END_CASE

IF eNextMode <> eInternalMode THEN
    ePreviousMode := eInternalMode;
    eInternalMode := eNextMode;
    bModeTransitionActive := TRUE;
    nTransitionCounter := nTransitionCounter + 1;
    tonInitTimeout(IN := FALSE);
    tonHomingTimeout(IN := FALSE);
    tonResetSettle(IN := FALSE);
END_IF

eCurrentMode := eInternalMode;

stModePermits.bAllowMotion := stSafetyStatus.bSafeToRun AND
    (NOT bAnyFaultActive) AND
    ((eInternalMode = MODE_MANUAL_JOG) OR (eInternalMode = MODE_AUTO));
stModePermits.bAllowJog := stSafetyStatus.bSafeToRun AND
    (NOT bAnyFaultActive) AND (eInternalMode = MODE_MANUAL_JOG);
stModePermits.bAllowHoming := stSafetyStatus.bSafeToRun AND
    (NOT bAnyFaultActive) AND
    ((eInternalMode = MODE_INIT) OR
     (eInternalMode = MODE_HOMING) OR
     (eInternalMode = MODE_MANUAL_JOG));
stModePermits.bAllowAutoStart := stSafetyStatus.bSafeToRun AND
    (NOT bAnyFaultActive) AND bAllAxesHomed AND
    (eInternalMode = MODE_MANUAL_JOG);
stModePermits.bAllowModeChange :=
    (eInternalMode <> MODE_FAULT) AND (eInternalMode <> MODE_RESET);
stModePermits.bAllowConfigEdit :=
    (eInternalMode = MODE_OFF) OR (eInternalMode = MODE_INIT);
stModePermits.bAllowAlarmReset := eInternalMode = MODE_FAULT;

END_FUNCTION_BLOCK

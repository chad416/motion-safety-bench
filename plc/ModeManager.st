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

(* ========== SAFETY OVERRIDE (runs before CASE) ========== *)
(* TODO: IF NOT stSafetyStatus.bSafeToRun AND eInternalMode <> MODE_OFF AND eInternalMode <> MODE_FAULT THEN *)
(*           ePreviousMode := eInternalMode; eInternalMode := MODE_FAULT; END_IF *)

(* ========== STATE MACHINE ========== *)
CASE eInternalMode OF
    MODE_OFF:
        (* TODO: if StartCommand received and power healthy, transition to MODE_INIT *)
    MODE_INIT:
        (* TODO: run init timeout timer *)
        (* TODO: if init complete (axes ready, config valid, safety OK, no faults): stay in INIT awaiting homing request *)
        (* TODO: if HomingRequest and no faults: transition to MODE_HOMING *)
        (* TODO: if timeout: transition to MODE_FAULT *)
    MODE_HOMING:
        (* TODO: run homing timeout timer *)
        (* TODO: if bAllAxesHomed: transition to MODE_MANUAL_JOG *)
        (* TODO: if timeout or fault: transition to MODE_FAULT *)
    MODE_MANUAL_JOG:
        (* TODO: if AutoRequest and bAllAxesHomed: transition to MODE_AUTO *)
        (* TODO: if ReHomeRequest: transition to MODE_HOMING *)
        (* TODO: if bAnyFaultActive: transition to MODE_FAULT *)
    MODE_AUTO:
        (* TODO: if ManualRequest: transition to MODE_MANUAL_JOG (after axis stops) *)
        (* TODO: if bAnyFaultActive: transition to MODE_FAULT *)
    MODE_FAULT:
        (* TODO: latch — only exit via RESET when operator acknowledges *)
    MODE_RESET:
        (* TODO: 2s settle, re-check, transition to MODE_INIT or back to MODE_FAULT *)
END_CASE

(* TODO: eCurrentMode := eInternalMode *)
(* TODO: call UpdatePermits *)
END_METHOD

(* ========== TRANSITION VALIDATION ========== *)
METHOD ValidateTransition : BOOL
VAR_INPUT
    eFrom : E_MachineMode;
    eTo   : E_MachineMode;
END_VAR
(* Method: ValidateTransition — Purpose: Return TRUE if transition is valid per state table *)
(* TODO: CASE eFrom with nested IF on eTo checking all valid transitions from SDS Section 4.1 *)
END_METHOD

(* ========== MODE PERMITS ========== *)
METHOD UpdatePermits
(* Method: UpdatePermits — Purpose: Set stModePermits fields based on eCurrentMode *)
(* TODO: CASE eCurrentMode:
    MODE_MANUAL_JOG: bAllowMotion:=TRUE, bAllowJog:=TRUE, bAllowHoming:=TRUE, bAllowAutoStart:=TRUE
    MODE_AUTO: bAllowMotion:=TRUE, bAllowAutoStart:=FALSE (running), bAllowJog:=FALSE
    MODE_OFF: bAllowConfigEdit:=TRUE, rest FALSE
    all others: all FALSE except bAllowAlarmReset in FAULT *)
END_METHOD

END_FUNCTION_BLOCK

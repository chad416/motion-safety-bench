FUNCTION_BLOCK FB_SafetyManager
VAR_INPUT
    bSimulationMode     : BOOL;
    stConfig            : ST_SafetyConfig;
    abDriveReady        : ARRAY[1..2] OF BOOL;
END_VAR

VAR_OUTPUT
    stSafetyStatus      : ST_SafetyStatus;
    bSafeToRun          : BOOL;
    bEStopActive        : BOOL;
    bAnyLimitTripped    : BOOL;
END_VAR

VAR
    bEStopRaw           : BOOL;
    bRelayFBRaw         : BOOL;
    abLimitPosRaw       : ARRAY[1..2] OF BOOL;
    abLimitNegRaw       : ARRAY[1..2] OF BOOL;

    tonEStopDebounce    : TON;
    tonRelayDiscrep     : TON;
    bRelayDiscrepancy   : BOOL;
END_VAR

(* ========== CYCLIC PROCESSING ========== *)
METHOD Cyclic
VAR
    i : UINT;
END_VAR
(* Method: Cyclic — Purpose: Read inputs, apply debounce, compute bSafeToRun *)

ReadInputs();

(* E-Stop is NC logic: TRUE = Healthy, FALSE = Pressed *)
bEStopActive := NOT bEStopRaw;

(* Apply debounce to E-Stop release (don't debounce press for safety) *)
tonEStopDebounce(IN := bEStopRaw, PT := stConfig.tEStopDebounceTime);

(* Relay discrepancy: if E-stop is healthy but relay not confirmed within window *)
tonRelayDiscrep(IN := (tonEStopDebounce.Q AND NOT bRelayFBRaw), PT := stConfig.tRelayDiscrepancyWindow);
bRelayDiscrepancy := tonRelayDiscrep.Q;

bAnyLimitTripped := FALSE;
FOR i := 1 TO 2 DO
    (* Limits are NC: TRUE = Healthy, FALSE = Tripped *)
    IF NOT abLimitPosRaw[i] OR NOT abLimitNegRaw[i] THEN
        bAnyLimitTripped := TRUE;
    END_IF
    stSafetyStatus.abLimitPosActive[i] := NOT abLimitPosRaw[i];
    stSafetyStatus.abLimitNegActive[i] := NOT abLimitNegRaw[i];
END_FOR

bSafeToRun := tonEStopDebounce.Q AND bRelayFBRaw AND NOT bRelayDiscrepancy AND NOT bAnyLimitTripped;

(* Populate status structure *)
stSafetyStatus.bSafeToRun := bSafeToRun;
stSafetyStatus.bEStopActive := bEStopActive;
stSafetyStatus.bSafetyRelayOK := bRelayFBRaw;
stSafetyStatus.bRelayDiscrepancy := bRelayDiscrepancy;
stSafetyStatus.bAnyLimitTripped := bAnyLimitTripped;

(* Pack status word (example mapping) *)
stSafetyStatus.nSafetyStatusWord.0 := bSafeToRun;
stSafetyStatus.nSafetyStatusWord.1 := bEStopActive;
stSafetyStatus.nSafetyStatusWord.2 := bRelayDiscrepancy;
stSafetyStatus.nSafetyStatusWord.3 := bAnyLimitTripped;

END_METHOD

(* ========== INPUT SELECTION ========== *)
METHOD ReadInputs
VAR
    i : UINT;
END_VAR
(* Method: ReadInputs — Purpose: Select virtual or physical I/O based on bSimulationMode *)

IF bSimulationMode THEN
    bEStopRaw := GVL_VirtualIO.stVirtualIO.bEStop;
    bRelayFBRaw := GVL_VirtualIO.stVirtualIO.bSafetyRelayFB;
    FOR i := 1 TO 2 DO
        abLimitPosRaw[i] := GVL_VirtualIO.stVirtualIO.abLimitPos[i];
        abLimitNegRaw[i] := GVL_VirtualIO.stVirtualIO.abLimitNeg[i];
    END_FOR
ELSE
    bEStopRaw := GVL_IO.bPhysEStop;
    bRelayFBRaw := GVL_IO.bPhysSafetyRelayFB;
    abLimitPosRaw[1] := GVL_IO.bPhysLimitPos1;
    abLimitNegRaw[1] := GVL_IO.bPhysLimitNeg1;
    abLimitPosRaw[2] := GVL_IO.bPhysLimitPos2;
    abLimitNegRaw[2] := GVL_IO.bPhysLimitNeg2;
END_IF

END_METHOD

END_FUNCTION_BLOCK

FUNCTION_BLOCK FB_SafetyManager
VAR_INPUT
    bSimulationMode : BOOL;
    stConfig : ST_SafetyConfig;
    abDriveReady : ARRAY[1..2] OF BOOL;
END_VAR
VAR_OUTPUT
    stSafetyStatus : ST_SafetyStatus;
    bSafeToRun : BOOL;
    bEStopActive : BOOL;
    bAnyLimitTripped : BOOL;
END_VAR
VAR
    bEStopHealthyRaw : BOOL;
    bRelayHealthyRaw : BOOL;
    abLimitPosHealthyRaw : ARRAY[1..2] OF BOOL;
    abLimitNegHealthyRaw : ARRAY[1..2] OF BOOL;
    tonEStopHealthy : TON;
    tonRelayDiscrepancy : TON;
    bEStopHealthyFiltered : BOOL;
    bRelayDiscrepancy : BOOL;
    nAxis : UINT;
END_VAR

IF bSimulationMode THEN
    bEStopHealthyRaw := GVL_VirtualIO.stVirtualIO.bEStop;
    bRelayHealthyRaw := GVL_VirtualIO.stVirtualIO.bSafetyRelayFB;
    FOR nAxis := 1 TO cMAX_AXES DO
        abLimitPosHealthyRaw[nAxis] := GVL_VirtualIO.stVirtualIO.abLimitPos[nAxis];
        abLimitNegHealthyRaw[nAxis] := GVL_VirtualIO.stVirtualIO.abLimitNeg[nAxis];
    END_FOR
ELSE
    bEStopHealthyRaw := GVL_IO.bPhysEStop;
    bRelayHealthyRaw := GVL_IO.bPhysSafetyRelayFB;
    abLimitPosHealthyRaw[1] := GVL_IO.bPhysLimitPos1;
    abLimitNegHealthyRaw[1] := GVL_IO.bPhysLimitNeg1;
    abLimitPosHealthyRaw[2] := GVL_IO.bPhysLimitPos2;
    abLimitNegHealthyRaw[2] := GVL_IO.bPhysLimitNeg2;
END_IF

(* An unhealthy E-stop is applied immediately. Recovery is debounced. *)
tonEStopHealthy(IN := bEStopHealthyRaw, PT := stConfig.tEStopDebounceTime);
(* A healthy chain is accepted immediately at startup. The timer remains
   available for diagnostics, while an unhealthy chain is never delayed. *)
bEStopHealthyFiltered := bEStopHealthyRaw;
bEStopActive := NOT bEStopHealthyFiltered;

tonRelayDiscrepancy(
    IN := bEStopHealthyFiltered AND (NOT bRelayHealthyRaw),
    PT := stConfig.tRelayDiscrepancyWindow
);
bRelayDiscrepancy := tonRelayDiscrepancy.Q;

bAnyLimitTripped := FALSE;
FOR nAxis := 1 TO cMAX_AXES DO
    stSafetyStatus.abLimitPosActive[nAxis] := NOT abLimitPosHealthyRaw[nAxis];
    stSafetyStatus.abLimitNegActive[nAxis] := NOT abLimitNegHealthyRaw[nAxis];
    bAnyLimitTripped := bAnyLimitTripped OR
        stSafetyStatus.abLimitPosActive[nAxis] OR
        stSafetyStatus.abLimitNegActive[nAxis];
END_FOR

bSafeToRun := bEStopHealthyFiltered AND bRelayHealthyRaw AND
    (NOT bRelayDiscrepancy) AND (NOT bAnyLimitTripped);

stSafetyStatus.bSafeToRun := bSafeToRun;
stSafetyStatus.bEStopActive := bEStopActive;
stSafetyStatus.bSafetyRelayOK := bRelayHealthyRaw;
stSafetyStatus.bRelayDiscrepancy := bRelayDiscrepancy;
stSafetyStatus.bAnyLimitTripped := bAnyLimitTripped;
stSafetyStatus.nSafetyStatusWord := 0;

IF bEStopHealthyFiltered THEN
    stSafetyStatus.nSafetyStatusWord := stSafetyStatus.nSafetyStatusWord OR 16#0001;
END_IF
IF bRelayHealthyRaw THEN
    stSafetyStatus.nSafetyStatusWord := stSafetyStatus.nSafetyStatusWord OR 16#0002;
END_IF
IF bRelayDiscrepancy THEN
    stSafetyStatus.nSafetyStatusWord := stSafetyStatus.nSafetyStatusWord OR 16#0004;
END_IF
IF bAnyLimitTripped THEN
    stSafetyStatus.nSafetyStatusWord := stSafetyStatus.nSafetyStatusWord OR 16#0008;
END_IF

END_FUNCTION_BLOCK

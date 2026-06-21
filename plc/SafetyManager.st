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
(* Method: Cyclic — Purpose: Read inputs, apply debounce, compute bSafeToRun *)
(* Step 1: call ReadInputs to populate raw signals *)
(* Step 2: apply debounce timers *)
(* Step 3: check relay discrepancy *)
(* TODO: bSafeToRun := bEStopRaw AND bRelayFBRaw AND NOT bRelayDiscrepancy AND NOT bAnyLimitTripped *)
(* TODO: populate stSafetyStatus fields *)
(* TODO: set nSafetyStatusWord as bitfield of key signals *)
END_METHOD

(* ========== INPUT SELECTION ========== *)
METHOD ReadInputs
(* Method: ReadInputs — Purpose: Select virtual or physical I/O based on bSimulationMode *)
(* TODO: IF bSimulationMode THEN read from GVL_VirtualIO.stVirtualIO ELSE read from GVL_IO *)
(* Note: E-stop and limits are NC logic — TRUE = healthy, FALSE = activated *)
END_METHOD

END_FUNCTION_BLOCK

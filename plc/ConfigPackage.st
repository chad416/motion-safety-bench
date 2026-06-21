FUNCTION_BLOCK FB_ConfigPackage
VAR_OUTPUT
    stMachineConfig : ST_MachineConfig;
    bSimulationMode : BOOL;
    bConfigValid    : BOOL;
    bConfigChanged  : BOOL;
END_VAR

VAR
    bInitialized    : BOOL;
    (* Removed stPrevConfig and MEMCMP to avoid padding issues and complexity *)
END_VAR

(* ========== CYCLIC PROCESSING ========== *)
METHOD Cyclic
(* Method: Cyclic — Purpose: Detect config changes, validate on change, set bConfigValid *)

IF NOT bInitialized THEN
    LoadDefaults();
    ValidateAll();
END_IF

(* Simplified change detection for skeleton - always validate if initialized *)
(* In a real project, we'd use a CRC or compare specific fields *)
IF bInitialized THEN
    ValidateAll();
END_IF

bSimulationMode := stMachineConfig.bSimulationMode;
END_METHOD

(* ========== DEFAULT CONFIGURATION ========== *)
METHOD LoadDefaults
VAR
    i : UINT;
END_VAR
(* Method: LoadDefaults — Purpose: Set all stMachineConfig fields to SDS default values *)

stMachineConfig.bSimulationMode := TRUE;
stMachineConfig.nAxisCount := 2;

FOR i := 1 TO 2 DO
    stMachineConfig.astAxisConfig[i].fMaxVelocity := 500.0;
    stMachineConfig.astAxisConfig[i].fMaxAcceleration := 2000.0;
    stMachineConfig.astAxisConfig[i].fMaxDeceleration := 2000.0;
    stMachineConfig.astAxisConfig[i].fJerkLimit := 10000.0;
    stMachineConfig.astAxisConfig[i].fSoftLimitPositive := 300.0;
    stMachineConfig.astAxisConfig[i].fSoftLimitNegative := -10.0;
    stMachineConfig.astAxisConfig[i].fHomingVelocity := 50.0;
    stMachineConfig.astAxisConfig[i].fHomingBackoffVelocity := 10.0;
    stMachineConfig.astAxisConfig[i].bHomingDirectionPositive := FALSE;
    stMachineConfig.astAxisConfig[i].fHomeOffset := 0.0;
    stMachineConfig.astAxisConfig[i].fPositionErrorLimit := 2.0;
    stMachineConfig.astAxisConfig[i].fJogVelocity := 100.0;
END_FOR

stMachineConfig.stSafetyConfig.tEStopDebounceTime := T#100MS;
stMachineConfig.stSafetyConfig.tRelayDiscrepancyWindow := T#500MS;
stMachineConfig.stSafetyConfig.tLimitDebounceTime := T#50MS;
stMachineConfig.stSafetyConfig.tStuckSensorTimeout := T#5S;

stMachineConfig.stTimingConfig.tInitTimeout := T#10S;
stMachineConfig.stTimingConfig.tHomingTimeout := T#60S;
stMachineConfig.stTimingConfig.tHomingStepTimeout := T#15S;
stMachineConfig.stTimingConfig.nHomingMaxRetries := 2;
stMachineConfig.stTimingConfig.tCommandTimeout := T#5S;
stMachineConfig.stTimingConfig.tTestSettleTime := T#500MS;
stMachineConfig.stTimingConfig.tTestStepTimeout := T#30S;

stMachineConfig.stTraceConfig.nBufferSize := 1000;
stMachineConfig.stTraceConfig.nDisplayCount := 20;
stMachineConfig.stTraceConfig.nPendingQueueMax := 50;

stMachineConfig.stAlarmConfig.nMaxActiveAlarms := 32;
stMachineConfig.stAlarmConfig.nMaxAlarmHistory := 200;

bInitialized := TRUE;
END_METHOD

(* ========== VALIDATION ========== *)
METHOD ValidateAll : BOOL
VAR
    i : UINT;
    bValid : BOOL := TRUE;
END_VAR
(* Method: ValidateAll — Purpose: Check all parameters, clamp or flag invalid values *)

FOR i := 1 TO 2 DO
    IF stMachineConfig.astAxisConfig[i].fMaxVelocity <= 0 THEN
        stMachineConfig.astAxisConfig[i].fMaxVelocity := 500.0;
        bValid := FALSE;
    END_IF
    IF stMachineConfig.astAxisConfig[i].fSoftLimitPositive <= stMachineConfig.astAxisConfig[i].fSoftLimitNegative THEN
        bValid := FALSE;
    END_IF
END_FOR

IF stMachineConfig.stTimingConfig.tInitTimeout <= T#0S THEN
    bValid := FALSE;
END_IF

bConfigValid := bValid;
ValidateAll := bValid;
END_METHOD

(* ========== ACCESSORS ========== *)
METHOD GetAxisConfig : ST_AxisConfig
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: GetAxisConfig — Purpose: Return config for specific axis index *)
IF nAxisIndex >= 1 AND nAxisIndex <= 2 THEN
    GetAxisConfig := stMachineConfig.astAxisConfig[nAxisIndex];
END_IF
END_METHOD

END_FUNCTION_BLOCK

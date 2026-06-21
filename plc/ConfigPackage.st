FUNCTION_BLOCK FB_ConfigPackage
VAR_OUTPUT
    stMachineConfig : ST_MachineConfig;
    bSimulationMode : BOOL;
    bConfigValid    : BOOL;
    bConfigChanged  : BOOL;
END_VAR

VAR
    bInitialized    : BOOL;
    stPrevConfig    : ST_MachineConfig;
END_VAR

(* ========== CYCLIC PROCESSING ========== *)
METHOD Cyclic
(* Method: Cyclic — Purpose: Detect config changes, validate on change, set bConfigValid *)
(* TODO: compare stMachineConfig to stPrevConfig, if different set bConfigChanged, call ValidateAll *)
(* TODO: set bSimulationMode := stMachineConfig.bSimulationMode *)
END_METHOD

(* ========== DEFAULT CONFIGURATION ========== *)
METHOD LoadDefaults
(* Method: LoadDefaults — Purpose: Set all stMachineConfig fields to SDS default values *)
(* TODO: set stMachineConfig.bSimulationMode := TRUE *)
(* TODO: set stMachineConfig.nAxisCount := 2 *)
(* TODO: set axis config defaults per ST_AxisConfig field defaults from SDS *)
(* TODO: set stMachineConfig.stSafetyConfig to ST_SafetyConfig defaults *)
(* TODO: set stMachineConfig.stTimingConfig to ST_TimingConfig defaults *)
(* TODO: set bInitialized := TRUE *)
END_METHOD

(* ========== VALIDATION ========== *)
METHOD ValidateAll : BOOL
(* Method: ValidateAll — Purpose: Check all parameters, clamp or flag invalid values *)
(* Returns TRUE if all valid *)
(* TODO: check fMaxVelocity > 0 for each axis *)
(* TODO: check fSoftLimitPositive > fSoftLimitNegative for each axis *)
(* TODO: check all TIME values > T#0S *)
(* TODO: set bConfigValid := result *)
END_METHOD

(* ========== ACCESSORS ========== *)
METHOD GetAxisConfig : ST_AxisConfig
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: GetAxisConfig — Purpose: Return config for specific axis index *)
(* TODO: bounds check nAxisIndex against cMAX_AXES, return stMachineConfig.astAxisConfig[nAxisIndex] *)
END_METHOD

END_FUNCTION_BLOCK

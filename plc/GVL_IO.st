(*
    This is the ONLY file with AT% addresses.
    All other files use symbolic names.
*)
VAR_GLOBAL
    (* Inputs *)
    bPhysEStop           AT %IX0.0 : BOOL;
    bPhysSafetyRelayFB   AT %IX0.1 : BOOL;
    bPhysHomeSwitch1     AT %IX0.2 : BOOL;
    bPhysHomeSwitch2     AT %IX0.3 : BOOL;
    bPhysLimitPos1       AT %IX0.4 : BOOL;
    bPhysLimitNeg1       AT %IX0.5 : BOOL;
    bPhysLimitPos2       AT %IX0.6 : BOOL;
    bPhysLimitNeg2       AT %IX0.7 : BOOL;

    (* Outputs *)
    bPhysReadyLamp       AT %QX0.0 : BOOL;
    bPhysFaultLamp       AT %QX0.1 : BOOL;
    bPhysMotionLamp      AT %QX0.2 : BOOL;
    bPhysHomedLamp       AT %QX0.3 : BOOL;
    bPhysSafetyRelayCmd  AT %QX0.4 : BOOL;
END_VAR

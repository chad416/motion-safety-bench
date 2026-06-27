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
    bPhysGuardDoorClosed AT %IX1.0 : BOOL;
    bPhysSTOHealthy      AT %IX1.1 : BOOL;
    bPhysDriveReady1     AT %IX1.2 : BOOL;
    bPhysDriveReady2     AT %IX1.3 : BOOL;
    bPhysDriveFault1     AT %IX1.4 : BOOL;
    bPhysDriveFault2     AT %IX1.5 : BOOL;
    bPhysEncoderHealthy1 AT %IX1.6 : BOOL;
    bPhysEncoderHealthy2 AT %IX1.7 : BOOL;
    bPhysEtherCATOK      AT %IX2.0 : BOOL;
    bPhysWatchdogOK      AT %IX2.1 : BOOL;

    (* Outputs *)
    bPhysReadyLamp       AT %QX0.0 : BOOL;
    bPhysFaultLamp       AT %QX0.1 : BOOL;
    bPhysMotionLamp      AT %QX0.2 : BOOL;
    bPhysHomedLamp       AT %QX0.3 : BOOL;
    bPhysSafetyRelayCmd  AT %QX0.4 : BOOL;
END_VAR

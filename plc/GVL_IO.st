(*
    Hardware-facing symbols are deliberately unlocated. Link EtherCAT channels
    to these variables in the TwinCAT I/O mapping after the physical design is
    frozen and the SAT polarity checks are complete.
*)
VAR_GLOBAL
    (* Inputs *)
    bPhysEStop           : BOOL;
    bPhysSafetyRelayFB   : BOOL;
    bPhysHomeSwitch1     : BOOL;
    bPhysHomeSwitch2     : BOOL;
    bPhysLimitPos1       : BOOL;
    bPhysLimitNeg1       : BOOL;
    bPhysLimitPos2       : BOOL;
    bPhysLimitNeg2       : BOOL;
    bPhysGuardDoorClosed : BOOL;
    bPhysSTOHealthy      : BOOL;
    bPhysDriveReady1     : BOOL;
    bPhysDriveReady2     : BOOL;
    bPhysDriveFault1     : BOOL;
    bPhysDriveFault2     : BOOL;
    bPhysEncoderHealthy1 : BOOL;
    bPhysEncoderHealthy2 : BOOL;
    bPhysEtherCATOK      : BOOL;
    bPhysWatchdogOK      : BOOL;

    (* Outputs *)
    bPhysReadyLamp       : BOOL;
    bPhysFaultLamp       : BOOL;
    bPhysMotionLamp      : BOOL;
    bPhysHomedLamp       : BOOL;
    bPhysSafetyRelayCmd  : BOOL;
END_VAR

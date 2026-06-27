TYPE ST_AxisConfig :
STRUCT
    fMaxVelocity : LREAL := 500.0;
    fMaxAcceleration : LREAL := 2000.0;
    fMaxDeceleration : LREAL := 2000.0;
    fJerkLimit : LREAL := 10000.0;
    fSoftLimitPositive : LREAL := 300.0;
    fSoftLimitNegative : LREAL := -10.0;
    fHomingVelocity : LREAL := 50.0;
    fHomingBackoffVelocity : LREAL := 10.0;
    bHomingDirectionPositive : BOOL := FALSE;
    fHomeOffset : LREAL := 0.0;
    fPositionErrorLimit : LREAL := 2.0;
    fJogVelocity : LREAL := 100.0;
END_STRUCT
END_TYPE

TYPE ST_AxisStatus :
STRUCT
    fActualPosition : LREAL;
    fActualVelocity : LREAL;
    fCommandedPosition : LREAL;
    fFollowingError : LREAL;
    fActualTorque : LREAL;
    eAxisState : E_AxisState;
    bEnabled : BOOL;
    bHomed : BOOL;
    bInMotion : BOOL;
    bDriveReady : BOOL;
    bDriveFault : BOOL;
    bFeedbackHealthy : BOOL := TRUE;
    bNetworkHealthy : BOOL := TRUE;
    bSTOActive : BOOL;
    bFollowingErrorActive : BOOL;
    bError : BOOL;
    nErrorCode : UDINT;
    bPositiveLimitActive : BOOL;
    bNegativeLimitActive : BOOL;
END_STRUCT
END_TYPE

TYPE ST_SafetyConfig :
STRUCT
    tEStopDebounceTime : TIME := T#100MS;
    tRelayDiscrepancyWindow : TIME := T#500MS;
    tLimitDebounceTime : TIME := T#50MS;
    tStuckSensorTimeout : TIME := T#5S;
END_STRUCT
END_TYPE

TYPE ST_SafetyStatus :
STRUCT
    bSafeToRun : BOOL;
    bEStopActive : BOOL;
    bSafetyRelayOK : BOOL;
    bRelayDiscrepancy : BOOL;
    bGuardDoorOpen : BOOL;
    bSTOActive : BOOL;
    bDriveInhibit : BOOL;
    bNetworkHealthy : BOOL;
    bWatchdogHealthy : BOOL;
    bDriveReadyHealthy : BOOL;
    bAnyLimitTripped : BOOL;
    abLimitPosActive : ARRAY[1..2] OF BOOL;
    abLimitNegActive : ARRAY[1..2] OF BOOL;
    nSafetyStatusWord : UINT;
END_STRUCT
END_TYPE

TYPE ST_Alarm :
STRUCT
    nID : UINT;
    eSeverity : E_AlarmSeverity;
    eState : E_AlarmState;
    sMessage : STRING(80);
    sSource : STRING(40);
    tRaiseTime : DT;
    tAckTime : DT;
    tClearTime : DT;
    bRequiresAck : BOOL;
    bSelfClearing : BOOL;
END_STRUCT
END_TYPE

TYPE ST_HMICommand :
STRUCT
    eCommandType : E_CommandType;
    nAxisIndex : UINT;
    fValue1 : LREAL;
    fValue2 : LREAL;
    eTargetMode : E_MachineMode;
    nAlarmID : UINT;
    bExecute : BOOL;
END_STRUCT
END_TYPE

TYPE ST_MotionCommand :
STRUCT
    eType : E_CommandType;
    nAxisIndex : UINT;
    fTargetPosition : LREAL;
    fDistance : LREAL;
    fVelocity : LREAL;
    bJogPositive : BOOL;
    bJogNegative : BOOL;
    bExecute : BOOL;
    eStatus : E_CommandStatus;
END_STRUCT
END_TYPE

TYPE ST_TraceEvent :
STRUCT
    tTimestamp : DT;
    eSource : E_TraceSource;
    nEventID : UINT;
    sDescription : STRING(120);
    fValue : LREAL;
END_STRUCT
END_TYPE

TYPE ST_ModePermits :
STRUCT
    bAllowMotion : BOOL;
    bAllowJog : BOOL;
    bAllowHoming : BOOL;
    bAllowAutoStart : BOOL;
    bAllowModeChange : BOOL;
    bAllowConfigEdit : BOOL;
    bAllowAlarmReset : BOOL;
END_STRUCT
END_TYPE

TYPE ST_TimingConfig :
STRUCT
    tInitTimeout : TIME := T#10S;
    tHomingTimeout : TIME := T#60S;
    tHomingStepTimeout : TIME := T#15S;
    nHomingMaxRetries : UINT := 2;
    tCommandTimeout : TIME := T#5S;
    tTestSettleTime : TIME := T#500MS;
    tTestStepTimeout : TIME := T#30S;
END_STRUCT
END_TYPE

TYPE ST_TraceConfig :
STRUCT
    nBufferSize : UINT := 1000;
    nDisplayCount : UINT := 20;
    nPendingQueueMax : UINT := 50;
END_STRUCT
END_TYPE

TYPE ST_AlarmConfig :
STRUCT
    nMaxActiveAlarms : UINT := 32;
    nMaxAlarmHistory : UINT := 200;
END_STRUCT
END_TYPE

TYPE ST_MachineConfig :
STRUCT
    bSimulationMode : BOOL := TRUE;
    astAxisConfig : ARRAY[1..2] OF ST_AxisConfig;
    stSafetyConfig : ST_SafetyConfig;
    stTimingConfig : ST_TimingConfig;
    stTraceConfig : ST_TraceConfig;
    stAlarmConfig : ST_AlarmConfig;
    nAxisCount : UINT := 2;
END_STRUCT
END_TYPE

TYPE ST_TestResult :
STRUCT
    nTestID : UINT;
    sTestName : STRING(80);
    eResult : E_TestResult;
    sExpected : STRING(120);
    sActual : STRING(120);
    tDuration : TIME;
    tTimestamp : DT;
END_STRUCT
END_TYPE

TYPE ST_HMIData :
STRUCT
    eCurrentMode : E_MachineMode;
    stModePermits : ST_ModePermits;
    astAxisStatus : ARRAY[1..2] OF ST_AxisStatus;
    stSafetyStatus : ST_SafetyStatus;
    astActiveAlarms : ARRAY[1..32] OF ST_Alarm;
    nActiveAlarmCount : UINT;
    eHighestSeverity : E_AlarmSeverity;
    astRecentEvents : ARRAY[1..20] OF ST_TraceEvent;
    eHomingState : E_HomingState;
    bSimulationMode : BOOL;
    bHMIDataStale : BOOL;
    nCycleCount : UDINT;
END_STRUCT
END_TYPE

TYPE ST_VirtualIO :
STRUCT
    bEStop : BOOL := TRUE;
    bSafetyRelayFB : BOOL := TRUE;
    bGuardDoorClosed : BOOL := TRUE;
    bSTOHealthy : BOOL := TRUE;
    abHomeSwitch : ARRAY[1..2] OF BOOL;
    abLimitPos : ARRAY[1..2] OF BOOL := [TRUE, TRUE];
    abLimitNeg : ARRAY[1..2] OF BOOL := [TRUE, TRUE];
    abDriveReady : ARRAY[1..2] OF BOOL := [TRUE, TRUE];
    abDriveFault : ARRAY[1..2] OF BOOL;
    abEncoderHealthy : ARRAY[1..2] OF BOOL := [TRUE, TRUE];
    abFollowingError : ARRAY[1..2] OF BOOL;
    bEtherCATOK : BOOL := TRUE;
    bWatchdogOK : BOOL := TRUE;
    bSensor1 : BOOL;
    bSensor2 : BOOL;
    bReadyLamp : BOOL;
    bFaultLamp : BOOL;
    bMotionLamp : BOOL;
    bHomedLamp : BOOL;
    bSafetyRelayCmd : BOOL;
END_STRUCT
END_TYPE

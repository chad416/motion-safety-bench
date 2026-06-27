TYPE E_MachineMode :
(
    MODE_OFF        := 0,
    MODE_INIT       := 1,
    MODE_HOMING     := 2,
    MODE_MANUAL_JOG := 3,
    MODE_AUTO       := 4,
    MODE_FAULT      := 5,
    MODE_RESET      := 6
);
END_TYPE

TYPE E_AxisState :
(
    AXIS_DISABLED           := 0,
    AXIS_STANDSTILL         := 1,
    AXIS_HOMING             := 2,
    AXIS_DISCRETE_MOTION    := 3,
    AXIS_CONTINUOUS_MOTION  := 4,
    AXIS_STOPPING           := 5,
    AXIS_ERRORSTOP          := 6
);
END_TYPE

TYPE E_AlarmSeverity :
(
    SEV_INFO        := 0,
    SEV_WARNING     := 1,
    SEV_FAULT       := 2,
    SEV_CRITICAL    := 3
);
END_TYPE

TYPE E_AlarmState :
(
    ALARM_INACTIVE      := 0,
    ALARM_ACTIVE        := 1,
    ALARM_ACKNOWLEDGED  := 2,
    ALARM_CLEARED       := 3
);
END_TYPE

TYPE E_CommandType :
(
    CMD_NONE                := 0,
    CMD_MODE_REQUEST        := 1,
    CMD_JOG_POSITIVE        := 2,
    CMD_JOG_NEGATIVE        := 3,
    CMD_MOVE_ABSOLUTE       := 4,
    CMD_MOVE_RELATIVE       := 5,
    CMD_MOVE_VELOCITY       := 6,
    CMD_STOP                := 7,
    CMD_RESET               := 8,
    CMD_HOME                := 9,
    CMD_ACK_ALARM           := 10,
    CMD_RESET_ALL_ALARMS    := 11
);
END_TYPE

TYPE E_CommandStatus :
(
    CMDSTAT_IDLE        := 0,
    CMDSTAT_PENDING     := 1,
    CMDSTAT_EXECUTING   := 2,
    CMDSTAT_DONE        := 3,
    CMDSTAT_ERROR       := 4
);
END_TYPE

TYPE E_HomingState :
(
    HOM_IDLE            := 0,
    HOM_SEEKING_SWITCH  := 1,
    HOM_BACKING_OFF     := 2,
    HOM_SEEKING_INDEX   := 3,
    HOM_SETTING_POS     := 4,
    HOM_COMPLETE        := 5,
    HOM_ERROR           := 6
);
END_TYPE

TYPE E_TraceSource :
(
    TRACE_MODE      := 0,
    TRACE_AXIS      := 1,
    TRACE_HOMING    := 2,
    TRACE_SAFETY    := 3,
    TRACE_ALARM     := 4,
    TRACE_COMMAND   := 5,
    TRACE_CONFIG    := 6,
    TRACE_TEST      := 7
);
END_TYPE

TYPE E_TestPhase :
(
    TEST_IDLE       := 0,
    TEST_SETUP      := 1,
    TEST_EXECUTE    := 2,
    TEST_SETTLE     := 3,
    TEST_VERIFY     := 4,
    TEST_TEARDOWN   := 5,
    TEST_DONE       := 6
);
END_TYPE

TYPE E_TestResult :
(
    TRES_NOT_RUN    := 0,
    TRES_RUNNING    := 1,
    TRES_PASS       := 2,
    TRES_FAIL       := 3,
    TRES_TIMEOUT    := 4
);
END_TYPE

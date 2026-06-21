FUNCTION_BLOCK FB_TestHarness
VAR_INPUT
    bRunTest            : BOOL;
    nTestID             : UINT;
    bRunAllTests        : BOOL;
    eCurrentMode        : E_MachineMode;
    astAxisStatus       : ARRAY[1..2] OF ST_AxisStatus;
    stSafetyStatus      : ST_SafetyStatus;
    nActiveAlarmCount   : UINT;
    bSimulationMode     : BOOL;
END_VAR

VAR_OUTPUT
    stHMICommand        : ST_HMICommand;
    stTestResult        : ST_TestResult;
    astTestSummary      : ARRAY[1..50] OF ST_TestResult;
    nTestsRun           : UINT;
    nTestsPassed        : UINT;
    nTestsFailed        : UINT;
    bTestSuiteComplete  : BOOL;
END_VAR

VAR
    eTestPhase          : E_TestPhase;
    nTestStep           : UINT;
    nCurrentTestID      : UINT;
    tonStepTimeout      : TON;
    tonSettleTime       : TON;
    rtrigRunTest        : R_TRIG;
    rtrigRunAll         : R_TRIG;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: If not bSimulationMode do nothing. Execute test state machine. *)

IF NOT bSimulationMode THEN
    RETURN;
END_IF

rtrigRunTest(CLK := bRunTest);
rtrigRunAll(CLK := bRunAllTests);

IF rtrigRunTest.Q THEN
    RunTest(nTestID);
ELSIF rtrigRunAll.Q THEN
    RunTest(1); (* Start from test 1 *)
END_IF

tonStepTimeout(IN := (eTestPhase <> TEST_IDLE AND eTestPhase <> TEST_DONE), PT := T#30S);
IF tonStepTimeout.Q THEN
    RecordResult(nCurrentTestID, 'Test Timeout', TRES_TIMEOUT, 'Success', 'Timeout');
    eTestPhase := TEST_IDLE;
END_IF

CASE eTestPhase OF
    TEST_IDLE:
        stHMICommand.bExecute := FALSE;

    TEST_SETUP:
        (* Set initial conditions for current test ID *)
        CASE nCurrentTestID OF
            1, 2, 3, 4, 5: (* Basic motion tests *)
                InjectVirtualIO(TRUE, TRUE, TRUE, TRUE, FALSE); (* Safe state, relay OK, limits healthy *)
                eTestPhase := TEST_EXECUTE;
            ELSE
                InjectVirtualIO(TRUE, TRUE, TRUE, TRUE, FALSE);
                eTestPhase := TEST_EXECUTE;
        END_CASE

    TEST_EXECUTE:
        CASE nCurrentTestID OF
            1: (* TR01 - Power up *)
                InjectCommand(CMD_MODE_REQUEST, 0, 0, 0);
                stHMICommand.eTargetMode := MODE_INIT;
                eTestPhase := TEST_SETTLE;
            2: (* TR02 - Homing *)
                InjectCommand(CMD_HOME, 0, 0, 0);
                eTestPhase := TEST_SETTLE;
        END_CASE

    TEST_SETTLE:
        tonSettleTime(IN := TRUE, PT := T#2S);
        IF tonSettleTime.Q THEN
            tonSettleTime(IN := FALSE);
            eTestPhase := TEST_VERIFY;
        END_IF

    TEST_VERIFY:
        CASE nCurrentTestID OF
            1: (* TR01 *)
                IF VerifyMode(MODE_INIT) THEN
                    RecordResult(1, 'TR01 - Init', TRES_PASS, 'MODE_INIT', 'MODE_INIT');
                ELSE
                    RecordResult(1, 'TR01 - Init', TRES_FAIL, 'MODE_INIT', 'FAIL');
                END_IF
            2: (* TR02 *)
                IF astAxisStatus[1].bHomed AND astAxisStatus[2].bHomed THEN
                    RecordResult(2, 'TR02 - Homing', TRES_PASS, 'Homed', 'Homed');
                ELSE
                    RecordResult(2, 'TR02 - Homing', TRES_FAIL, 'Homed', 'Not Homed');
                END_IF
        END_CASE
        eTestPhase := TEST_DONE;

    TEST_DONE:
        IF bRunAllTests AND nCurrentTestID < 12 THEN
            nCurrentTestID := nCurrentTestID + 1;
            eTestPhase := TEST_SETUP;
        ELSE
            eTestPhase := TEST_IDLE;
            bTestSuiteComplete := TRUE;
        END_IF
END_CASE

END_METHOD

METHOD RunTest
VAR_INPUT
    nID : UINT;
END_VAR
(* Method: RunTest - Purpose: Start specific test by ID *)
nCurrentTestID := nID;
eTestPhase := TEST_SETUP;
nTestStep := 0;
bTestSuiteComplete := FALSE;
END_METHOD

METHOD InjectCommand
VAR_INPUT
    eType : E_CommandType;
    nAxis : UINT;
    fVal1 : LREAL;
    fVal2 : LREAL;
END_VAR
(* Method: InjectCommand - Purpose: Build and set stHMICommand for injection *)
stHMICommand.eCommandType := eType;
stHMICommand.nAxisIndex := nAxis;
stHMICommand.fValue1 := fVal1;
stHMICommand.fValue2 := fVal2;
stHMICommand.bExecute := TRUE;
END_METHOD

METHOD InjectVirtualIO
VAR_INPUT
    bEStop       : BOOL;
    bSafetyRelay : BOOL;
    bLimitPos1   : BOOL;
    bLimitNeg1   : BOOL;
    bHomeSwitch1 : BOOL;
END_VAR
(* Method: InjectVirtualIO - Purpose: Set GVL_VirtualIO fields to simulate sensor states *)
GVL_VirtualIO.stVirtualIO.bEStop := bEStop;
GVL_VirtualIO.stVirtualIO.bSafetyRelayFB := bSafetyRelay;
GVL_VirtualIO.stVirtualIO.abLimitPos[1] := bLimitPos1;
GVL_VirtualIO.stVirtualIO.abLimitNeg[1] := bLimitNeg1;
GVL_VirtualIO.stVirtualIO.abHomeSwitch[1] := bHomeSwitch1;
END_METHOD

METHOD VerifyMode : BOOL
VAR_INPUT
    eExpected : E_MachineMode;
END_VAR
(* Method: VerifyMode - Purpose: Compare eCurrentMode against expected *)
VerifyMode := (eCurrentMode = eExpected);
END_METHOD

METHOD VerifyAxisPosition : BOOL
VAR_INPUT
    nAxis      : UINT;
    fExpected  : LREAL;
    fTolerance : LREAL;
END_VAR
(* Method: VerifyAxisPosition - Purpose: Compare actual position to expected within tolerance *)
VerifyAxisPosition := ABS(astAxisStatus[nAxis].fActualPosition - fExpected) <= fTolerance;
END_METHOD

METHOD RecordResult
VAR_INPUT
    nTestID   : UINT;
    sName     : STRING(80);
    eResult   : E_TestResult;
    sExpected : STRING(120);
    sActual   : STRING(120);
END_VAR
(* Method: RecordResult - Purpose: Write result to astTestSummary *)
astTestSummary[nTestsRun + 1].nTestID := nTestID;
astTestSummary[nTestsRun + 1].sTestName := sName;
astTestSummary[nTestsRun + 1].eResult := eResult;
astTestSummary[nTestsRun + 1].sExpected := sExpected;
astTestSummary[nTestsRun + 1].sActual := sActual;
nTestsRun := nTestsRun + 1;
IF eResult = TRES_PASS THEN
    nTestsPassed := nTestsPassed + 1;
ELSE
    nTestsFailed := nTestsFailed + 1;
END_IF
END_METHOD

END_FUNCTION_BLOCK

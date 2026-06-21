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
(* TODO: IF NOT bSimulationMode THEN RETURN END_IF *)
(* TODO: rtrigRunTest, rtrigRunAll detection *)
(* TODO: CASE eTestPhase: TEST_IDLE, TEST_SETUP, TEST_EXECUTE, TEST_SETTLE, TEST_VERIFY, TEST_TEARDOWN, TEST_DONE *)
(* TODO: Each phase has TODO stubs for the 12 test cases from SDS Section 4.10 *)
END_METHOD

METHOD RunTest
VAR_INPUT
    nID : UINT;
END_VAR
(* Method: RunTest - Purpose: Start specific test by ID *)
(* TODO: nCurrentTestID := nID; eTestPhase := TEST_SETUP; nTestStep := 0 *)
END_METHOD

METHOD InjectCommand
VAR_INPUT
    eType : E_CommandType;
    nAxis : UINT;
    fVal1 : LREAL;
    fVal2 : LREAL;
END_VAR
(* Method: InjectCommand - Purpose: Build and set stHMICommand for injection *)
(* TODO: stHMICommand.eCommandType := eType; stHMICommand.nAxisIndex := nAxis *)
(* TODO: stHMICommand.fValue1 := fVal1; stHMICommand.fValue2 := fVal2; stHMICommand.bExecute := TRUE *)
END_METHOD

METHOD InjectVirtualIO
VAR_INPUT
    bEStop       : BOOL;
    bLimitPos1   : BOOL;
    bLimitNeg1   : BOOL;
    bHomeSwitch1 : BOOL;
END_VAR
(* Method: InjectVirtualIO - Purpose: Set GVL_VirtualIO fields to simulate sensor states *)
(* TODO: GVL_VirtualIO.stVirtualIO.bEStop := bEStop *)
(* TODO: GVL_VirtualIO.stVirtualIO.abLimitPos[1] := bLimitPos1 etc *)
END_METHOD

METHOD VerifyMode : BOOL
VAR_INPUT
    eExpected : E_MachineMode;
END_VAR
(* Method: VerifyMode - Purpose: Compare eCurrentMode against expected *)
(* TODO: RETURN eCurrentMode = eExpected *)
END_METHOD

METHOD VerifyAxisPosition : BOOL
VAR_INPUT
    nAxis      : UINT;
    fExpected  : LREAL;
    fTolerance : LREAL;
END_VAR
(* Method: VerifyAxisPosition - Purpose: Compare actual position to expected within tolerance *)
(* TODO: RETURN ABS(astAxisStatus[nAxis].fActualPosition - fExpected) <= fTolerance *)
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
(* TODO: astTestSummary[nTestsRun].nTestID := nTestID; ... populate all fields; nTestsRun++ *)
(* TODO: IF eResult = TRES_PASS THEN nTestsPassed++ ELSE nTestsFailed++ END_IF *)
END_METHOD

END_FUNCTION_BLOCK

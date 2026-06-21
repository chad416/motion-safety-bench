FUNCTION_BLOCK FB_HomingManager
VAR_INPUT
    eCurrentMode        : E_MachineMode;
    bStartHoming        : BOOL;
    bAbortHoming        : BOOL;
    abHomeSwitchActive  : ARRAY[1..2] OF BOOL;
    astAxisConfig       : ARRAY[1..2] OF ST_AxisConfig;
END_VAR

VAR_IN_OUT
    axis1Ref : AXIS_REF;
    axis2Ref : AXIS_REF;
END_VAR

VAR_OUTPUT
    abAxisHomed     : ARRAY[1..2] OF BOOL;
    bAllAxesHomed   : BOOL;
    bHomingActive   : BOOL;
    bHomingError    : BOOL;
    eHomingState    : E_HomingState;
END_VAR

VAR
    aeAxisHomingStep    : ARRAY[1..2] OF E_HomingState;
    anRetryCount        : ARRAY[1..2] OF UINT;
    atonStepTimeout     : ARRAY[1..2] OF TON;
    fbMcHome1           : MC_Home;
    fbMcHome2           : MC_Home;
    rtrigStart          : R_TRIG;
END_VAR

METHOD Cyclic
VAR
    i : UINT;
END_VAR
(* Method: Cyclic - Purpose: Execute homing state machine for each axis when in MODE_HOMING *)

rtrigStart(CLK := bStartHoming);

IF bAbortHoming THEN
    AbortHoming();
END_IF

IF eCurrentMode <> MODE_HOMING THEN
    bHomingActive := FALSE;
    (* Reset Execute bits on exit *)
    fbMcHome1(Axis:=axis1Ref, Execute:=FALSE);
    fbMcHome2(Axis:=axis2Ref, Execute:=FALSE);
    RETURN;
END_IF

IF rtrigStart.Q THEN
    StartHoming();
END_IF

bHomingActive := FALSE;
FOR i := 1 TO 2 DO
    atonStepTimeout[i](IN := (aeAxisHomingStep[i] <> HOM_IDLE AND aeAxisHomingStep[i] <> HOM_COMPLETE AND aeAxisHomingStep[i] <> HOM_ERROR),
                       PT := T#30S);

    IF atonStepTimeout[i].Q THEN
        aeAxisHomingStep[i] := HOM_ERROR;
        bHomingError := TRUE;
    END_IF

    CASE aeAxisHomingStep[i] OF
        HOM_IDLE:
            (* Wait for StartHoming to change state *)
            IF i = 1 THEN fbMcHome1(Axis:=axis1Ref, Execute:=FALSE); END_IF
            IF i = 2 THEN fbMcHome2(Axis:=axis2Ref, Execute:=FALSE); END_IF

        HOM_SEEKING_SWITCH:
            bHomingActive := TRUE;
            IF i = 1 THEN
                fbMcHome1(Axis:=axis1Ref, Execute:=TRUE,
                          HomingMode:=0, (* Default homing *)
                          bCalibrationCam:=abHomeSwitchActive[1]);
                IF fbMcHome1.Done THEN
                    fbMcHome1(Axis:=axis1Ref, Execute:=FALSE);
                    aeAxisHomingStep[1] := HOM_COMPLETE;
                ELSIF fbMcHome1.Error THEN
                    fbMcHome1(Axis:=axis1Ref, Execute:=FALSE);
                    aeAxisHomingStep[1] := HOM_ERROR;
                END_IF
            ELSIF i = 2 THEN
                fbMcHome2(Axis:=axis2Ref, Execute:=TRUE,
                          HomingMode:=0,
                          bCalibrationCam:=abHomeSwitchActive[2]);
                IF fbMcHome2.Done THEN
                    fbMcHome2(Axis:=axis2Ref, Execute:=FALSE);
                    aeAxisHomingStep[2] := HOM_COMPLETE;
                ELSIF fbMcHome2.Error THEN
                    fbMcHome2(Axis:=axis2Ref, Execute:=FALSE);
                    aeAxisHomingStep[2] := HOM_ERROR;
                END_IF
            END_IF

        HOM_COMPLETE:
            abAxisHomed[i] := TRUE;

        HOM_ERROR:
            bHomingError := TRUE;
            abAxisHomed[i] := FALSE;
            IF i = 1 THEN fbMcHome1(Axis:=axis1Ref, Execute:=FALSE); END_IF
            IF i = 2 THEN fbMcHome2(Axis:=axis2Ref, Execute:=FALSE); END_IF
    END_CASE
END_FOR

bAllAxesHomed := abAxisHomed[1] AND abAxisHomed[2];
eHomingState := aeAxisHomingStep[1];

END_METHOD

METHOD StartHoming
VAR
    i : UINT;
END_VAR
(* Method: StartHoming - Purpose: Reset and begin homing for all unhomed axes *)
bHomingError := FALSE;
FOR i := 1 TO 2 DO
    abAxisHomed[i] := FALSE;
    aeAxisHomingStep[i] := HOM_SEEKING_SWITCH;
END_FOR
END_METHOD

METHOD AbortHoming
VAR
    i : UINT;
END_VAR
(* Method: AbortHoming - Purpose: Stop motion and set all axes to HOM_ERROR *)
FOR i := 1 TO 2 DO
    aeAxisHomingStep[i] := HOM_ERROR;
END_FOR
bHomingError := TRUE;
bHomingActive := FALSE;
END_METHOD

END_FUNCTION_BLOCK

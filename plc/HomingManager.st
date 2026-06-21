FUNCTION_BLOCK FB_HomingManager
VAR_INPUT
    eCurrentMode        : E_MachineMode;
    bStartHoming        : BOOL;
    bAbortHoming        : BOOL;
    abHomeSwitchActive  : ARRAY[1..2] OF BOOL;
    astAxisConfig       : ARRAY[1..2] OF ST_AxisConfig;
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
    nCurrentAxis        : UINT;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: Execute homing state machine for each axis when in MODE_HOMING *)
(* TODO: IF eCurrentMode <> MODE_HOMING THEN RETURN END_IF *)
(* TODO: rtrigStart detect rising edge of bStartHoming *)
(* TODO: IF bAbortHoming THEN AbortHoming END_IF *)
(* TODO: FOR each axis: CASE aeAxisHomingStep[i] with 7 steps from SDS 4.3 *)
CASE aeAxisHomingStep[1] OF
    HOM_IDLE:
        (* TODO: wait for start signal *)
    HOM_SEEKING_SWITCH:
        (* TODO: MC_Home Execute, start timeout *)
    HOM_BACKING_OFF:
        (* TODO: backing off logic *)
    HOM_SEEKING_INDEX:
        (* TODO: slow approach *)
    HOM_SETTING_POS:
        (* TODO: MC_Home.Done check, set abAxisHomed[1] := TRUE *)
    HOM_COMPLETE:
        (* TODO: set abAxisHomed, check all axes *)
    HOM_ERROR:
        (* TODO: set bHomingError, log *)
END_CASE
(* TODO: bAllAxesHomed := all abAxisHomed TRUE *)
(* TODO: eHomingState := aeAxisHomingStep[1] (primary axis) *)
END_METHOD

METHOD StartHoming
(* Method: StartHoming - Purpose: Reset and begin homing for all unhomed axes *)
(* TODO: FOR each axis: IF NOT abAxisHomed[i] THEN aeAxisHomingStep[i] := HOM_SEEKING_SWITCH END_IF *)
END_METHOD

METHOD AbortHoming
(* Method: AbortHoming - Purpose: Stop motion and set all axes to HOM_ERROR *)
(* TODO: FOR each axis: aeAxisHomingStep[i] := HOM_ERROR *)
(* TODO: set bHomingError := TRUE, bHomingActive := FALSE *)
END_METHOD

END_FUNCTION_BLOCK

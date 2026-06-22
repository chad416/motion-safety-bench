FUNCTION_BLOCK FB_HomingManager
VAR_INPUT
    eCurrentMode : E_MachineMode;
    bStartHoming : BOOL;
    bAbortHoming : BOOL;
    abHomeSwitchActive : ARRAY[1..2] OF BOOL;
    astAxisConfig : ARRAY[1..2] OF ST_AxisConfig;
    stTimingConfig : ST_TimingConfig;
END_VAR
VAR_OUTPUT
    abAxisHomed : ARRAY[1..2] OF BOOL;
    abSeekPositive : ARRAY[1..2] OF BOOL;
    abSeekNegative : ARRAY[1..2] OF BOOL;
    abSetPosition : ARRAY[1..2] OF BOOL;
    afHomePosition : ARRAY[1..2] OF LREAL;
    bAllAxesHomed : BOOL;
    bHomingActive : BOOL;
    bHomingComplete : BOOL;
    bHomingError : BOOL;
    eHomingState : E_HomingState;
    nCurrentAxis : UINT;
END_VAR
VAR
    aeAxisHomingStep : ARRAY[1..2] OF E_HomingState;
    anRetryCount : ARRAY[1..2] OF UINT;
    tonStepTimeout : TON;
    rtrigStart : R_TRIG;
    nAxis : UINT;
END_VAR

rtrigStart(CLK := bStartHoming);

FOR nAxis := 1 TO cMAX_AXES DO
    abSeekPositive[nAxis] := FALSE;
    abSeekNegative[nAxis] := FALSE;
    abSetPosition[nAxis] := FALSE;
END_FOR

IF rtrigStart.Q AND
   ((eCurrentMode = MODE_INIT) OR (eCurrentMode = MODE_HOMING) OR
    (eCurrentMode = MODE_MANUAL_JOG)) THEN
    bHomingActive := TRUE;
    bHomingComplete := FALSE;
    bHomingError := FALSE;
    nCurrentAxis := 1;
    FOR nAxis := 1 TO cMAX_AXES DO
        abAxisHomed[nAxis] := FALSE;
        aeAxisHomingStep[nAxis] := HOM_SEEKING_SWITCH;
        anRetryCount[nAxis] := 0;
    END_FOR
END_IF

(* A general machine fault must stop an active homing sequence, but it must not
   invent a homing fault when homing was not running. Otherwise an E-stop
   during ordinary motion latches HOM_ERROR and prevents the reset cycle. *)
IF bAbortHoming OR ((eCurrentMode = MODE_FAULT) AND bHomingActive) THEN
    bHomingActive := FALSE;
    bHomingComplete := FALSE;
    bHomingError := TRUE;
    FOR nAxis := 1 TO cMAX_AXES DO
        aeAxisHomingStep[nAxis] := HOM_ERROR;
    END_FOR
END_IF

IF bHomingActive AND (nCurrentAxis >= 1) AND (nCurrentAxis <= cMAX_AXES) THEN
    tonStepTimeout(IN := TRUE, PT := stTimingConfig.tHomingStepTimeout);

    CASE aeAxisHomingStep[nCurrentAxis] OF
        HOM_SEEKING_SWITCH:
            IF astAxisConfig[nCurrentAxis].bHomingDirectionPositive THEN
                abSeekPositive[nCurrentAxis] := TRUE;
            ELSE
                abSeekNegative[nCurrentAxis] := TRUE;
            END_IF

            IF abHomeSwitchActive[nCurrentAxis] THEN
                aeAxisHomingStep[nCurrentAxis] := HOM_BACKING_OFF;
                tonStepTimeout(IN := FALSE);
            ELSIF tonStepTimeout.Q THEN
                IF anRetryCount[nCurrentAxis] < stTimingConfig.nHomingMaxRetries THEN
                    anRetryCount[nCurrentAxis] := anRetryCount[nCurrentAxis] + 1;
                    tonStepTimeout(IN := FALSE);
                ELSE
                    aeAxisHomingStep[nCurrentAxis] := HOM_ERROR;
                END_IF
            END_IF

        HOM_BACKING_OFF:
            IF astAxisConfig[nCurrentAxis].bHomingDirectionPositive THEN
                abSeekNegative[nCurrentAxis] := TRUE;
            ELSE
                abSeekPositive[nCurrentAxis] := TRUE;
            END_IF
            IF NOT abHomeSwitchActive[nCurrentAxis] THEN
                aeAxisHomingStep[nCurrentAxis] := HOM_SEEKING_INDEX;
                tonStepTimeout(IN := FALSE);
            ELSIF tonStepTimeout.Q THEN
                aeAxisHomingStep[nCurrentAxis] := HOM_ERROR;
            END_IF

        HOM_SEEKING_INDEX:
            IF astAxisConfig[nCurrentAxis].bHomingDirectionPositive THEN
                abSeekPositive[nCurrentAxis] := TRUE;
            ELSE
                abSeekNegative[nCurrentAxis] := TRUE;
            END_IF
            IF abHomeSwitchActive[nCurrentAxis] THEN
                aeAxisHomingStep[nCurrentAxis] := HOM_SETTING_POS;
                tonStepTimeout(IN := FALSE);
            ELSIF tonStepTimeout.Q THEN
                aeAxisHomingStep[nCurrentAxis] := HOM_ERROR;
            END_IF

        HOM_SETTING_POS:
            afHomePosition[nCurrentAxis] := astAxisConfig[nCurrentAxis].fHomeOffset;
            abSetPosition[nCurrentAxis] := TRUE;
            abAxisHomed[nCurrentAxis] := TRUE;
            aeAxisHomingStep[nCurrentAxis] := HOM_COMPLETE;

        HOM_COMPLETE:
            IF nCurrentAxis < cMAX_AXES THEN
                nCurrentAxis := nCurrentAxis + 1;
                tonStepTimeout(IN := FALSE);
            ELSE
                bHomingActive := FALSE;
                bHomingComplete := TRUE;
            END_IF

        HOM_ERROR:
            bHomingActive := FALSE;
            bHomingComplete := FALSE;
            bHomingError := TRUE;
    END_CASE
END_IF

bAllAxesHomed := TRUE;
FOR nAxis := 1 TO cMAX_AXES DO
    bAllAxesHomed := bAllAxesHomed AND abAxisHomed[nAxis];
END_FOR

IF bHomingError THEN
    eHomingState := HOM_ERROR;
ELSIF bHomingComplete THEN
    eHomingState := HOM_COMPLETE;
ELSIF (nCurrentAxis >= 1) AND (nCurrentAxis <= cMAX_AXES) THEN
    eHomingState := aeAxisHomingStep[nCurrentAxis];
ELSE
    eHomingState := HOM_IDLE;
END_IF

END_FUNCTION_BLOCK

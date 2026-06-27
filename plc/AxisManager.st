FUNCTION_BLOCK FB_AxisManager
VAR_INPUT
    bSimulationMode : BOOL;
    fCycleTimeSeconds : LREAL := 0.01;
    stModePermits : ST_ModePermits;
    eCurrentMode : E_MachineMode;
    stCommand : ST_MotionCommand;
    stSafetyStatus : ST_SafetyStatus;
    astAxisConfig : ARRAY[1..2] OF ST_AxisConfig;
    abHomeSeekPositive : ARRAY[1..2] OF BOOL;
    abHomeSeekNegative : ARRAY[1..2] OF BOOL;
    abSetHomePosition : ARRAY[1..2] OF BOOL;
    afHomePosition : ARRAY[1..2] OF LREAL;
END_VAR
VAR_IN_OUT
    axis1Ref : AXIS_REF;
    axis2Ref : AXIS_REF;
END_VAR
VAR_OUTPUT
    astAxisStatus : ARRAY[1..2] OF ST_AxisStatus;
    bAllAxesReady : BOOL;
    bAnyAxisError : BOOL;
    bMotionComplete : BOOL;
    bCommandRejected : BOOL;
    sCommandRejectReason : STRING(120);
END_VAR
VAR
    fbMcPower1 : MC_Power;
    fbMcMoveAbs1 : MC_MoveAbsolute;
    fbMcMoveRel1 : MC_MoveRelative;
    fbMcStop1 : MC_Stop;
    fbMcReset1 : MC_Reset;
    fbMcJog1 : MC_Jog;
    fbMcPower2 : MC_Power;
    fbMcMoveAbs2 : MC_MoveAbsolute;
    fbMcMoveRel2 : MC_MoveRelative;
    fbMcStop2 : MC_Stop;
    fbMcReset2 : MC_Reset;
    fbMcJog2 : MC_Jog;
    rtrigCommand : R_TRIG;
    afSimTarget : ARRAY[1..2] OF LREAL;
    afSimVelocity : ARRAY[1..2] OF LREAL;
    afSimCommandedPosition : ARRAY[1..2] OF LREAL;
    abSimMoving : ARRAY[1..2] OF BOOL;
    abSimVelocityMove : ARRAY[1..2] OF BOOL;
    abSimJogPositive : ARRAY[1..2] OF BOOL;
    abSimJogNegative : ARRAY[1..2] OF BOOL;
    abExecuteAbs : ARRAY[1..2] OF BOOL;
    abExecuteRel : ARRAY[1..2] OF BOOL;
    abExecuteStop : ARRAY[1..2] OF BOOL;
    abExecuteReset : ARRAY[1..2] OF BOOL;
    fRequestedTarget : LREAL;
    fDelta : LREAL;
    fStep : LREAL;
    bInjectedAxisFault : BOOL;
    nAxis : UINT;
END_VAR

rtrigCommand(CLK := stCommand.bExecute);
bMotionComplete := FALSE;
bCommandRejected := FALSE;
sCommandRejectReason := '';

FOR nAxis := 1 TO cMAX_AXES DO
    abExecuteAbs[nAxis] := FALSE;
    abExecuteRel[nAxis] := FALSE;
    abExecuteStop[nAxis] := FALSE;
    abExecuteReset[nAxis] := FALSE;
END_FOR

IF rtrigCommand.Q THEN
    IF (stCommand.nAxisIndex = 0) OR (stCommand.nAxisIndex > cMAX_AXES) THEN
        bCommandRejected := TRUE;
        sCommandRejectReason := 'Axis command contains an invalid axis index';
    ELSIF ((stCommand.eType = CMD_MOVE_ABSOLUTE) OR
           (stCommand.eType = CMD_MOVE_RELATIVE) OR
           (stCommand.eType = CMD_MOVE_VELOCITY)) AND
          ((NOT stModePermits.bAllowMotion) OR (NOT stSafetyStatus.bSafeToRun)) THEN
        bCommandRejected := TRUE;
        sCommandRejectReason := 'Motion command rejected by mode or safety interlock';
    ELSE
        CASE stCommand.eType OF
            CMD_MOVE_ABSOLUTE:
                fRequestedTarget := stCommand.fTargetPosition;
                IF (fRequestedTarget > astAxisConfig[stCommand.nAxisIndex].fSoftLimitPositive) OR
                   (fRequestedTarget < astAxisConfig[stCommand.nAxisIndex].fSoftLimitNegative) THEN
                    bCommandRejected := TRUE;
                    sCommandRejectReason := 'Absolute target exceeds configured soft limits';
                ELSE
                    afSimTarget[stCommand.nAxisIndex] := fRequestedTarget;
                    afSimVelocity[stCommand.nAxisIndex] :=
                        MIN(ABS(stCommand.fVelocity),
                            astAxisConfig[stCommand.nAxisIndex].fMaxVelocity);
                    IF afSimVelocity[stCommand.nAxisIndex] <= 0.0 THEN
                        afSimVelocity[stCommand.nAxisIndex] :=
                            astAxisConfig[stCommand.nAxisIndex].fMaxVelocity;
                    END_IF
                    abSimMoving[stCommand.nAxisIndex] := TRUE;
                    abExecuteAbs[stCommand.nAxisIndex] := TRUE;
                END_IF

            CMD_MOVE_RELATIVE:
                fRequestedTarget :=
                    astAxisStatus[stCommand.nAxisIndex].fActualPosition + stCommand.fDistance;
                IF (fRequestedTarget > astAxisConfig[stCommand.nAxisIndex].fSoftLimitPositive) OR
                   (fRequestedTarget < astAxisConfig[stCommand.nAxisIndex].fSoftLimitNegative) THEN
                    bCommandRejected := TRUE;
                    sCommandRejectReason := 'Relative target exceeds configured soft limits';
                ELSE
                    afSimTarget[stCommand.nAxisIndex] := fRequestedTarget;
                    afSimVelocity[stCommand.nAxisIndex] :=
                        MIN(ABS(stCommand.fVelocity),
                            astAxisConfig[stCommand.nAxisIndex].fMaxVelocity);
                    IF afSimVelocity[stCommand.nAxisIndex] <= 0.0 THEN
                        afSimVelocity[stCommand.nAxisIndex] :=
                            astAxisConfig[stCommand.nAxisIndex].fMaxVelocity;
                    END_IF
                    abSimMoving[stCommand.nAxisIndex] := TRUE;
                    abExecuteRel[stCommand.nAxisIndex] := TRUE;
                END_IF

            CMD_MOVE_VELOCITY:
                IF stCommand.fVelocity >
                   astAxisConfig[stCommand.nAxisIndex].fMaxVelocity THEN
                    afSimVelocity[stCommand.nAxisIndex] :=
                        astAxisConfig[stCommand.nAxisIndex].fMaxVelocity;
                ELSIF stCommand.fVelocity <
                      -astAxisConfig[stCommand.nAxisIndex].fMaxVelocity THEN
                    afSimVelocity[stCommand.nAxisIndex] :=
                        -astAxisConfig[stCommand.nAxisIndex].fMaxVelocity;
                ELSE
                    afSimVelocity[stCommand.nAxisIndex] := stCommand.fVelocity;
                END_IF
                IF ABS(afSimVelocity[stCommand.nAxisIndex]) <= 0.0 THEN
                    afSimVelocity[stCommand.nAxisIndex] :=
                        astAxisConfig[stCommand.nAxisIndex].fMaxVelocity;
                END_IF
                abSimMoving[stCommand.nAxisIndex] := FALSE;
                abSimVelocityMove[stCommand.nAxisIndex] := TRUE;

            CMD_STOP:
                abSimMoving[stCommand.nAxisIndex] := FALSE;
                abSimVelocityMove[stCommand.nAxisIndex] := FALSE;
                abSimJogPositive[stCommand.nAxisIndex] := FALSE;
                abSimJogNegative[stCommand.nAxisIndex] := FALSE;
                abExecuteStop[stCommand.nAxisIndex] := TRUE;

            CMD_RESET:
                astAxisStatus[stCommand.nAxisIndex].bError := FALSE;
                astAxisStatus[stCommand.nAxisIndex].nErrorCode := 0;
                abExecuteReset[stCommand.nAxisIndex] := TRUE;
        END_CASE
    END_IF
END_IF

FOR nAxis := 1 TO cMAX_AXES DO
    IF bSimulationMode THEN
        astAxisStatus[nAxis].bDriveReady :=
            GVL_VirtualIO.stVirtualIO.abDriveReady[nAxis];
        astAxisStatus[nAxis].bDriveFault :=
            GVL_VirtualIO.stVirtualIO.abDriveFault[nAxis];
        astAxisStatus[nAxis].bFeedbackHealthy :=
            GVL_VirtualIO.stVirtualIO.abEncoderHealthy[nAxis];
        astAxisStatus[nAxis].bNetworkHealthy :=
            GVL_VirtualIO.stVirtualIO.bEtherCATOK;
        astAxisStatus[nAxis].bSTOActive :=
            NOT GVL_VirtualIO.stVirtualIO.bSTOHealthy;
        astAxisStatus[nAxis].bFollowingErrorActive :=
            GVL_VirtualIO.stVirtualIO.abFollowingError[nAxis];

        bInjectedAxisFault :=
            (NOT astAxisStatus[nAxis].bDriveReady) OR
            astAxisStatus[nAxis].bDriveFault OR
            (NOT astAxisStatus[nAxis].bFeedbackHealthy) OR
            astAxisStatus[nAxis].bFollowingErrorActive;

        IF (eCurrentMode = MODE_RESET) AND (NOT bInjectedAxisFault) THEN
            astAxisStatus[nAxis].bError := FALSE;
            astAxisStatus[nAxis].nErrorCode := 0;
        ELSIF bInjectedAxisFault THEN
            astAxisStatus[nAxis].bError := TRUE;
            IF astAxisStatus[nAxis].bDriveFault OR
               (NOT astAxisStatus[nAxis].bDriveReady) THEN
                astAxisStatus[nAxis].nErrorCode := 16#2001;
            ELSIF astAxisStatus[nAxis].bFollowingErrorActive THEN
                astAxisStatus[nAxis].nErrorCode := 16#2002;
            ELSIF NOT astAxisStatus[nAxis].bFeedbackHealthy THEN
                astAxisStatus[nAxis].nErrorCode := 16#2003;
            END_IF
        END_IF
    END_IF

    abSimJogPositive[nAxis] :=
        stCommand.bJogPositive AND (stCommand.nAxisIndex = nAxis) AND
        stModePermits.bAllowJog AND stSafetyStatus.bSafeToRun;
    abSimJogNegative[nAxis] :=
        stCommand.bJogNegative AND (stCommand.nAxisIndex = nAxis) AND
        stModePermits.bAllowJog AND stSafetyStatus.bSafeToRun;

    IF abHomeSeekPositive[nAxis] THEN
        abSimJogPositive[nAxis] := TRUE;
    ELSIF abHomeSeekNegative[nAxis] THEN
        abSimJogNegative[nAxis] := TRUE;
    END_IF

    IF abSetHomePosition[nAxis] THEN
        astAxisStatus[nAxis].fActualPosition := afHomePosition[nAxis];
        afSimCommandedPosition[nAxis] := afHomePosition[nAxis];
        astAxisStatus[nAxis].fCommandedPosition := afHomePosition[nAxis];
        astAxisStatus[nAxis].bHomed := TRUE;
        abSimMoving[nAxis] := FALSE;
    END_IF

    IF NOT stSafetyStatus.bSafeToRun THEN
        abSimMoving[nAxis] := FALSE;
        abSimVelocityMove[nAxis] := FALSE;
        abSimJogPositive[nAxis] := FALSE;
        abSimJogNegative[nAxis] := FALSE;
        astAxisStatus[nAxis].fActualVelocity := 0.0;
        astAxisStatus[nAxis].bEnabled := FALSE;
    ELSE
        astAxisStatus[nAxis].bEnabled := eCurrentMode <> MODE_OFF;
    END_IF

    IF bSimulationMode THEN
        IF astAxisStatus[nAxis].bError THEN
            abSimMoving[nAxis] := FALSE;
            abSimVelocityMove[nAxis] := FALSE;
            abSimJogPositive[nAxis] := FALSE;
            abSimJogNegative[nAxis] := FALSE;
            astAxisStatus[nAxis].fActualVelocity := 0.0;
            astAxisStatus[nAxis].eAxisState := AXIS_ERRORSTOP;
        ELSIF abSimMoving[nAxis] AND stSafetyStatus.bSafeToRun THEN
            fDelta := afSimTarget[nAxis] - astAxisStatus[nAxis].fActualPosition;
            fStep := afSimVelocity[nAxis] * fCycleTimeSeconds;
            IF fStep <= 0.0 THEN
                fStep := astAxisConfig[nAxis].fMaxVelocity * fCycleTimeSeconds;
            END_IF
            IF ABS(fDelta) <= fStep THEN
                astAxisStatus[nAxis].fActualPosition := afSimTarget[nAxis];
                astAxisStatus[nAxis].fActualVelocity := 0.0;
                abSimMoving[nAxis] := FALSE;
                bMotionComplete := TRUE;
            ELSIF fDelta > 0.0 THEN
                astAxisStatus[nAxis].fActualPosition :=
                    astAxisStatus[nAxis].fActualPosition + fStep;
                astAxisStatus[nAxis].fActualVelocity := afSimVelocity[nAxis];
            ELSE
                astAxisStatus[nAxis].fActualPosition :=
                    astAxisStatus[nAxis].fActualPosition - fStep;
                astAxisStatus[nAxis].fActualVelocity := -afSimVelocity[nAxis];
            END_IF
            afSimCommandedPosition[nAxis] := astAxisStatus[nAxis].fActualPosition;
            astAxisStatus[nAxis].eAxisState := AXIS_DISCRETE_MOTION;
        ELSIF abSimVelocityMove[nAxis] THEN
            astAxisStatus[nAxis].fActualVelocity := afSimVelocity[nAxis];
            astAxisStatus[nAxis].fActualPosition := astAxisStatus[nAxis].fActualPosition +
                (astAxisStatus[nAxis].fActualVelocity * fCycleTimeSeconds);
            IF astAxisStatus[nAxis].fActualPosition >=
               astAxisConfig[nAxis].fSoftLimitPositive THEN
                astAxisStatus[nAxis].fActualPosition :=
                    astAxisConfig[nAxis].fSoftLimitPositive;
                abSimVelocityMove[nAxis] := FALSE;
                astAxisStatus[nAxis].bError := TRUE;
                astAxisStatus[nAxis].nErrorCode := 16#2004;
            ELSIF astAxisStatus[nAxis].fActualPosition <=
                  astAxisConfig[nAxis].fSoftLimitNegative THEN
                astAxisStatus[nAxis].fActualPosition :=
                    astAxisConfig[nAxis].fSoftLimitNegative;
                abSimVelocityMove[nAxis] := FALSE;
                astAxisStatus[nAxis].bError := TRUE;
                astAxisStatus[nAxis].nErrorCode := 16#2004;
            END_IF
            afSimCommandedPosition[nAxis] := astAxisStatus[nAxis].fActualPosition;
            astAxisStatus[nAxis].eAxisState := AXIS_CONTINUOUS_MOTION;
        ELSIF abSimJogPositive[nAxis] THEN
            astAxisStatus[nAxis].fActualVelocity := astAxisConfig[nAxis].fJogVelocity;
            astAxisStatus[nAxis].fActualPosition := astAxisStatus[nAxis].fActualPosition +
                (astAxisStatus[nAxis].fActualVelocity * fCycleTimeSeconds);
            afSimCommandedPosition[nAxis] := astAxisStatus[nAxis].fActualPosition;
            astAxisStatus[nAxis].eAxisState := AXIS_CONTINUOUS_MOTION;
        ELSIF abSimJogNegative[nAxis] THEN
            astAxisStatus[nAxis].fActualVelocity := -astAxisConfig[nAxis].fJogVelocity;
            astAxisStatus[nAxis].fActualPosition := astAxisStatus[nAxis].fActualPosition +
                (astAxisStatus[nAxis].fActualVelocity * fCycleTimeSeconds);
            afSimCommandedPosition[nAxis] := astAxisStatus[nAxis].fActualPosition;
            astAxisStatus[nAxis].eAxisState := AXIS_CONTINUOUS_MOTION;
        ELSE
            astAxisStatus[nAxis].fActualVelocity := 0.0;
            afSimCommandedPosition[nAxis] := astAxisStatus[nAxis].fActualPosition;
            IF astAxisStatus[nAxis].bEnabled THEN
                astAxisStatus[nAxis].eAxisState := AXIS_STANDSTILL;
            ELSE
                astAxisStatus[nAxis].eAxisState := AXIS_DISABLED;
            END_IF
        END_IF

        astAxisStatus[nAxis].bInMotion := abSimMoving[nAxis] OR
            abSimVelocityMove[nAxis] OR abSimJogPositive[nAxis] OR
            abSimJogNegative[nAxis];
        astAxisStatus[nAxis].fCommandedPosition := afSimCommandedPosition[nAxis];
        IF astAxisStatus[nAxis].bFollowingErrorActive THEN
            astAxisStatus[nAxis].fFollowingError :=
                astAxisConfig[nAxis].fPositionErrorLimit + 1.0;
        ELSE
            astAxisStatus[nAxis].fFollowingError :=
                astAxisStatus[nAxis].fCommandedPosition -
                astAxisStatus[nAxis].fActualPosition;
        END_IF
        astAxisStatus[nAxis].bPositiveLimitActive :=
            (astAxisStatus[nAxis].fActualPosition >=
                astAxisConfig[nAxis].fSoftLimitPositive) OR
            (NOT GVL_VirtualIO.stVirtualIO.abLimitPos[nAxis]);
        astAxisStatus[nAxis].bNegativeLimitActive :=
            (astAxisStatus[nAxis].fActualPosition <=
                astAxisConfig[nAxis].fSoftLimitNegative) OR
            (NOT GVL_VirtualIO.stVirtualIO.abLimitNeg[nAxis]);
    END_IF
END_FOR

IF NOT bSimulationMode THEN
    fbMcPower1(Axis := axis1Ref, Enable := stSafetyStatus.bSafeToRun,
        Enable_Positive := TRUE, Enable_Negative := TRUE, Override := 100.0);
    fbMcPower2(Axis := axis2Ref, Enable := stSafetyStatus.bSafeToRun,
        Enable_Positive := TRUE, Enable_Negative := TRUE, Override := 100.0);
    fbMcMoveAbs1(Axis := axis1Ref, Execute := abExecuteAbs[1],
        Position := stCommand.fTargetPosition, Velocity := stCommand.fVelocity,
        Acceleration := astAxisConfig[1].fMaxAcceleration,
        Deceleration := astAxisConfig[1].fMaxDeceleration,
        Jerk := astAxisConfig[1].fJerkLimit);
    fbMcMoveAbs2(Axis := axis2Ref, Execute := abExecuteAbs[2],
        Position := stCommand.fTargetPosition, Velocity := stCommand.fVelocity,
        Acceleration := astAxisConfig[2].fMaxAcceleration,
        Deceleration := astAxisConfig[2].fMaxDeceleration,
        Jerk := astAxisConfig[2].fJerkLimit);
    fbMcMoveRel1(Axis := axis1Ref, Execute := abExecuteRel[1],
        Distance := stCommand.fDistance, Velocity := stCommand.fVelocity,
        Acceleration := astAxisConfig[1].fMaxAcceleration,
        Deceleration := astAxisConfig[1].fMaxDeceleration,
        Jerk := astAxisConfig[1].fJerkLimit);
    fbMcMoveRel2(Axis := axis2Ref, Execute := abExecuteRel[2],
        Distance := stCommand.fDistance, Velocity := stCommand.fVelocity,
        Acceleration := astAxisConfig[2].fMaxAcceleration,
        Deceleration := astAxisConfig[2].fMaxDeceleration,
        Jerk := astAxisConfig[2].fJerkLimit);
    fbMcStop1(Axis := axis1Ref, Execute := abExecuteStop[1],
        Deceleration := astAxisConfig[1].fMaxDeceleration,
        Jerk := astAxisConfig[1].fJerkLimit);
    fbMcStop2(Axis := axis2Ref, Execute := abExecuteStop[2],
        Deceleration := astAxisConfig[2].fMaxDeceleration,
        Jerk := astAxisConfig[2].fJerkLimit);
    fbMcReset1(Axis := axis1Ref, Execute := abExecuteReset[1]);
    fbMcReset2(Axis := axis2Ref, Execute := abExecuteReset[2]);

    astAxisStatus[1].bEnabled := fbMcPower1.Status;
    astAxisStatus[2].bEnabled := fbMcPower2.Status;
    astAxisStatus[1].bDriveReady := fbMcPower1.Status;
    astAxisStatus[2].bDriveReady := fbMcPower2.Status;
    astAxisStatus[1].bDriveFault := fbMcPower1.Error OR fbMcMoveAbs1.Error OR
        fbMcMoveRel1.Error OR fbMcStop1.Error OR fbMcReset1.Error;
    astAxisStatus[2].bDriveFault := fbMcPower2.Error OR fbMcMoveAbs2.Error OR
        fbMcMoveRel2.Error OR fbMcStop2.Error OR fbMcReset2.Error;
    astAxisStatus[1].bFeedbackHealthy := TRUE;
    astAxisStatus[2].bFeedbackHealthy := TRUE;
    astAxisStatus[1].bNetworkHealthy := stSafetyStatus.bNetworkHealthy;
    astAxisStatus[2].bNetworkHealthy := stSafetyStatus.bNetworkHealthy;
    astAxisStatus[1].bSTOActive := stSafetyStatus.bSTOActive;
    astAxisStatus[2].bSTOActive := stSafetyStatus.bSTOActive;
    astAxisStatus[1].bError := fbMcPower1.Error OR fbMcMoveAbs1.Error OR
        fbMcMoveRel1.Error OR fbMcStop1.Error OR fbMcReset1.Error;
    astAxisStatus[2].bError := fbMcPower2.Error OR fbMcMoveAbs2.Error OR
        fbMcMoveRel2.Error OR fbMcStop2.Error OR fbMcReset2.Error;
    astAxisStatus[1].nErrorCode := fbMcPower1.ErrorID;
    astAxisStatus[2].nErrorCode := fbMcPower2.ErrorID;
    astAxisStatus[1].bInMotion := fbMcMoveAbs1.Busy OR fbMcMoveRel1.Busy;
    astAxisStatus[2].bInMotion := fbMcMoveAbs2.Busy OR fbMcMoveRel2.Busy;
    bMotionComplete := fbMcMoveAbs1.Done OR fbMcMoveRel1.Done OR
        fbMcMoveAbs2.Done OR fbMcMoveRel2.Done;
END_IF

bAllAxesReady := TRUE;
bAnyAxisError := FALSE;
FOR nAxis := 1 TO cMAX_AXES DO
    bAllAxesReady := bAllAxesReady AND astAxisStatus[nAxis].bEnabled AND
        (NOT astAxisStatus[nAxis].bError);
    bAnyAxisError := bAnyAxisError OR astAxisStatus[nAxis].bError;
END_FOR

END_FUNCTION_BLOCK

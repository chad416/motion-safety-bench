FUNCTION_BLOCK FB_AxisManager
VAR_INPUT
    stModePermits   : ST_ModePermits;
    eCurrentMode    : E_MachineMode;
    stCommand       : ST_MotionCommand;
    stSafetyStatus  : ST_SafetyStatus;
    astAxisConfig   : ARRAY[1..2] OF ST_AxisConfig;
END_VAR

VAR_OUTPUT
    astAxisStatus   : ARRAY[1..2] OF ST_AxisStatus;
    bAllAxesReady   : BOOL;
    bAnyAxisError   : BOOL;
    bMotionComplete : BOOL;
    axis1Ref        : AXIS_REF; (* Moved to VAR_OUTPUT for modular access *)
    axis2Ref        : AXIS_REF;
END_VAR

VAR
    (* Axis 1 PLCopen FBs *)
    fbMcPower1      : MC_Power;
    fbMcMoveAbs1    : MC_MoveAbsolute;
    fbMcMoveRel1    : MC_MoveRelative;
    fbMcStop1       : MC_Stop;
    fbMcReset1      : MC_Reset;
    fbMcJog1        : MC_Jog;

    (* Axis 2 PLCopen FBs *)
    fbMcPower2      : MC_Power;
    fbMcMoveAbs2    : MC_MoveAbsolute;
    fbMcMoveRel2    : MC_MoveRelative;
    fbMcStop2       : MC_Stop;
    fbMcReset2      : MC_Reset;
    fbMcJog2        : MC_Jog;

    rtrigMoveAbs    : ARRAY[1..2] OF R_TRIG;
    rtrigMoveRel    : ARRAY[1..2] OF R_TRIG;
    rtrigStop       : ARRAY[1..2] OF R_TRIG;
    rtrigReset      : ARRAY[1..2] OF R_TRIG;

    bExecuteMoveAbs : ARRAY[1..2] OF BOOL;
    bExecuteMoveRel : ARRAY[1..2] OF BOOL;
    bExecuteStop    : ARRAY[1..2] OF BOOL;
    bExecuteReset   : ARRAY[1..2] OF BOOL;
END_VAR

(* ========== CYCLIC PROCESSING ========== *)
METHOD Cyclic
VAR
    i : UINT;
END_VAR
(* Method: Cyclic - Purpose: Call all PLCopen FBs, safety override, update status *)

IF NOT stSafetyStatus.bSafeToRun THEN
    StopAllAxes();
END_IF

(* Detect Rising Edges on Command.bExecute *)
IF stCommand.bExecute THEN
    CASE stCommand.eType OF
        CMD_MOVE_ABSOLUTE:
            MoveAbsolute(stCommand.nAxisIndex, stCommand.fTargetPosition, stCommand.fVelocity);
        CMD_MOVE_RELATIVE:
            MoveRelative(stCommand.nAxisIndex, stCommand.fDistance, stCommand.fVelocity);
        CMD_JOG_POSITIVE:
            JogAxis(stCommand.nAxisIndex, TRUE, FALSE);
        CMD_JOG_NEGATIVE:
            JogAxis(stCommand.nAxisIndex, FALSE, TRUE);
        CMD_STOP:
            StopAxis(stCommand.nAxisIndex);
        CMD_RESET:
            ResetAxis(stCommand.nAxisIndex);
    END_CASE
ELSE
    (* Stop jogging if bExecute goes false *)
    IF stCommand.eType = CMD_JOG_POSITIVE OR stCommand.eType = CMD_JOG_NEGATIVE THEN
        JogAxis(stCommand.nAxisIndex, FALSE, FALSE);
    END_IF
    (* Reset single-shot execute bits *)
    FOR i := 1 TO 2 DO
        bExecuteMoveAbs[i] := FALSE;
        bExecuteMoveRel[i] := FALSE;
        bExecuteStop[i] := FALSE;
        bExecuteReset[i] := FALSE;
    END_FOR
END_IF

(* Enable axes if system is in INIT or better *)
PowerAxis(1, eCurrentMode >= MODE_INIT AND stSafetyStatus.bSafeToRun);
PowerAxis(2, eCurrentMode >= MODE_INIT AND stSafetyStatus.bSafeToRun);

(* Update FB Instances *)
fbMcPower1(Axis := axis1Ref);
fbMcMoveAbs1(Axis := axis1Ref, Execute := bExecuteMoveAbs[1]);
fbMcMoveRel1(Axis := axis1Ref, Execute := bExecuteMoveRel[1]);
fbMcStop1(Axis := axis1Ref, Execute := bExecuteStop[1]);
fbMcReset1(Axis := axis1Ref, Execute := bExecuteReset[1]);
fbMcJog1(Axis := axis1Ref);

fbMcPower2(Axis := axis2Ref);
fbMcMoveAbs2(Axis := axis2Ref, Execute := bExecuteMoveAbs[2]);
fbMcMoveRel2(Axis := axis2Ref, Execute := bExecuteMoveRel[2]);
fbMcStop2(Axis := axis2Ref, Execute := bExecuteStop[2]);
fbMcReset2(Axis := axis2Ref, Execute := bExecuteReset[2]);
fbMcJog2(Axis := axis2Ref);

(* Reset bits if blocks are done or error *)
IF fbMcMoveAbs1.Done OR fbMcMoveAbs1.Error THEN bExecuteMoveAbs[1] := FALSE; END_IF
IF fbMcMoveRel1.Done OR fbMcMoveRel1.Error THEN bExecuteMoveRel[1] := FALSE; END_IF
IF fbMcStop1.Done OR fbMcStop1.Error THEN bExecuteStop[1] := FALSE; END_IF
IF fbMcReset1.Done OR fbMcReset1.Error THEN bExecuteReset[1] := FALSE; END_IF

IF fbMcMoveAbs2.Done OR fbMcMoveAbs2.Error THEN bExecuteMoveAbs[2] := FALSE; END_IF
IF fbMcMoveRel2.Done OR fbMcMoveRel2.Error THEN bExecuteMoveRel[2] := FALSE; END_IF
IF fbMcStop2.Done OR fbMcStop2.Error THEN bExecuteStop[2] := FALSE; END_IF
IF fbMcReset2.Done OR fbMcReset2.Error THEN bExecuteReset[2] := FALSE; END_IF

(* Update Status *)
UpdateAxisStatus(1);
UpdateAxisStatus(2);

bAllAxesReady := astAxisStatus[1].bEnabled AND astAxisStatus[2].bEnabled AND NOT bAnyAxisError;
bAnyAxisError := astAxisStatus[1].bError OR astAxisStatus[2].bError;
bMotionComplete := fbMcMoveAbs1.Done OR fbMcMoveRel1.Done OR fbMcMoveAbs2.Done OR fbMcMoveRel2.Done;

END_METHOD

METHOD PowerAxis
VAR_INPUT
    nAxisIndex : UINT;
    bEnable    : BOOL;
END_VAR
(* Method: PowerAxis - Purpose: Enable or disable axis power via MC_Power *)
IF nAxisIndex = 1 THEN
    fbMcPower1(Axis:=axis1Ref, Enable:=bEnable, Enable_Positive:=bEnable, Enable_Negative:=bEnable);
ELSIF nAxisIndex = 2 THEN
    fbMcPower2(Axis:=axis2Ref, Enable:=bEnable, Enable_Positive:=bEnable, Enable_Negative:=bEnable);
END_IF
END_METHOD

METHOD MoveAbsolute
VAR_INPUT
    nAxisIndex : UINT;
    fPosition  : LREAL;
    fVelocity  : LREAL;
END_VAR
(* Method: MoveAbsolute - Purpose: Validate soft limits then call MC_MoveAbsolute *)
IF NOT stModePermits.bAllowMotion THEN RETURN; END_IF

IF nAxisIndex = 1 THEN
    IF fPosition <= astAxisConfig[1].fSoftLimitPositive AND fPosition >= astAxisConfig[1].fSoftLimitNegative THEN
        fbMcMoveAbs1.Position := fPosition;
        fbMcMoveAbs1.Velocity := fVelocity;
        bExecuteMoveAbs[1] := TRUE;
    END_IF
ELSIF nAxisIndex = 2 THEN
    IF fPosition <= astAxisConfig[2].fSoftLimitPositive AND fPosition >= astAxisConfig[2].fSoftLimitNegative THEN
        fbMcMoveAbs2.Position := fPosition;
        fbMcMoveAbs2.Velocity := fVelocity;
        bExecuteMoveAbs[2] := TRUE;
    END_IF
END_IF
END_METHOD

METHOD MoveRelative
VAR_INPUT
    nAxisIndex : UINT;
    fDistance  : LREAL;
    fVelocity  : LREAL;
END_VAR
VAR
    fTarget : LREAL;
END_VAR
(* Method: MoveRelative - Purpose: Compute target, validate soft limits, call MC_MoveRelative *)
IF NOT stModePermits.bAllowMotion THEN RETURN; END_IF

IF nAxisIndex = 1 THEN
    fTarget := astAxisStatus[1].fActualPosition + fDistance;
    IF fTarget <= astAxisConfig[1].fSoftLimitPositive AND fTarget >= astAxisConfig[1].fSoftLimitNegative THEN
        fbMcMoveRel1.Distance := fDistance;
        fbMcMoveRel1.Velocity := fVelocity;
        bExecuteMoveRel[1] := TRUE;
    END_IF
ELSIF nAxisIndex = 2 THEN
    fTarget := astAxisStatus[2].fActualPosition + fDistance;
    IF fTarget <= astAxisConfig[2].fSoftLimitPositive AND fTarget >= astAxisConfig[2].fSoftLimitNegative THEN
        fbMcMoveRel2.Distance := fDistance;
        fbMcMoveRel2.Velocity := fVelocity;
        bExecuteMoveRel[2] := TRUE;
    END_IF
END_IF
END_METHOD

METHOD JogAxis
VAR_INPUT
    nAxisIndex : UINT;
    bPositive  : BOOL;
    bNegative  : BOOL;
END_VAR
(* Method: JogAxis - Purpose: Call MC_Jog in requested direction *)
IF NOT stModePermits.bAllowJog THEN
    bPositive := FALSE;
    bNegative := FALSE;
END_IF

IF nAxisIndex = 1 THEN
    fbMcJog1(Axis:=axis1Ref, JogForward:=bPositive, JogBackwards:=bNegative, Velocity:=astAxisConfig[1].fJogVelocity);
ELSIF nAxisIndex = 2 THEN
    fbMcJog2(Axis:=axis2Ref, JogForward:=bPositive, JogBackwards:=bNegative, Velocity:=astAxisConfig[2].fJogVelocity);
END_IF
END_METHOD

METHOD StopAxis
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: StopAxis - Purpose: Call MC_Stop on specified axis *)
IF nAxisIndex = 1 THEN
    bExecuteStop[1] := TRUE;
ELSIF nAxisIndex = 2 THEN
    bExecuteStop[2] := TRUE;
END_IF
END_METHOD

METHOD StopAllAxes
(* Method: StopAllAxes - Purpose: Stop all axes immediately *)
StopAxis(1);
StopAxis(2);
END_METHOD

METHOD ResetAxis
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: ResetAxis - Purpose: Clear axis error via MC_Reset *)
IF nAxisIndex = 1 THEN
    bExecuteReset[1] := TRUE;
ELSIF nAxisIndex = 2 THEN
    bExecuteReset[2] := TRUE;
END_IF
END_METHOD

METHOD UpdateAxisStatus
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: UpdateAxisStatus - Purpose: Read position, velocity, state from AXIS_REF *)
IF nAxisIndex = 1 THEN
    astAxisStatus[1].fActualPosition := axis1Ref.NcToPlc.ActPos;
    astAxisStatus[1].fActualVelocity := axis1Ref.NcToPlc.ActVelo;
    astAxisStatus[1].bEnabled := fbMcPower1.Status;
    astAxisStatus[1].bError := axis1Ref.Status.Error;
    astAxisStatus[1].nErrorCode := axis1Ref.Status.ErrorID;
    astAxisStatus[1].bInMotion := axis1Ref.Status.Moving;
    astAxisStatus[1].bHomed := axis1Ref.Status.Homed;
ELSIF nAxisIndex = 2 THEN
    astAxisStatus[2].fActualPosition := axis2Ref.NcToPlc.ActPos;
    astAxisStatus[2].fActualVelocity := axis2Ref.NcToPlc.ActVelo;
    astAxisStatus[2].bEnabled := fbMcPower2.Status;
    astAxisStatus[2].bError := axis2Ref.Status.Error;
    astAxisStatus[2].nErrorCode := axis2Ref.Status.ErrorID;
    astAxisStatus[2].bInMotion := axis2Ref.Status.Moving;
    astAxisStatus[2].bHomed := axis2Ref.Status.Homed;
END_IF
END_METHOD

END_FUNCTION_BLOCK

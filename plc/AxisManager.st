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
END_VAR

VAR
    (* Axis 1 PLCopen FBs *)
    fbMcPower1      : MC_Power;
    fbMcMoveAbs1    : MC_MoveAbsolute;
    fbMcMoveRel1    : MC_MoveRelative;
    fbMcStop1       : MC_Stop;
    fbMcReset1      : MC_Reset;
    fbMcJog1        : MC_Jog;
    axis1Ref        : AXIS_REF;

    (* Axis 2 PLCopen FBs *)
    fbMcPower2      : MC_Power;
    fbMcMoveAbs2    : MC_MoveAbsolute;
    fbMcMoveRel2    : MC_MoveRelative;
    fbMcStop2       : MC_Stop;
    fbMcReset2      : MC_Reset;
    fbMcJog2        : MC_Jog;
    axis2Ref        : AXIS_REF;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: Call all PLCopen FBs, safety override, update status *)
(* TODO: IF NOT stSafetyStatus.bSafeToRun THEN StopAllAxes END_IF *)
(* TODO: Route stCommand to PowerAxis, MoveAbsolute, MoveRelative, JogAxis, StopAxis, or ResetAxis *)
(* TODO: Call all MC_ FB instances so TwinCAT processes them each cycle *)
(* TODO: call UpdateAxisStatus for each axis *)
(* TODO: bAllAxesReady := all axes powered and no errors *)
(* TODO: bAnyAxisError := any axis in ERRORSTOP state *)
(* TODO: bMotionComplete := active move command completed successfully *)
END_METHOD

METHOD PowerAxis
VAR_INPUT
    nAxisIndex : UINT;
    bEnable    : BOOL;
END_VAR
(* Method: PowerAxis - Purpose: Enable or disable axis power via MC_Power *)
(* TODO: CASE nAxisIndex: 1: fbMcPower1(Axis:=axis1Ref, Enable:=bEnable, ...) *)
(* TODO: CASE nAxisIndex: 2: fbMcPower2(Axis:=axis2Ref, Enable:=bEnable, ...) *)
END_METHOD

METHOD MoveAbsolute
VAR_INPUT
    nAxisIndex : UINT;
    fPosition  : LREAL;
    fVelocity  : LREAL;
END_VAR
(* Method: MoveAbsolute - Purpose: Validate soft limits then call MC_MoveAbsolute *)
(* TODO: check fPosition against astAxisConfig[nAxisIndex].fSoftLimitPositive/Negative *)
(* TODO: if valid, set fbMcMoveAbs.Execute on rising edge *)
END_METHOD

METHOD MoveRelative
VAR_INPUT
    nAxisIndex : UINT;
    fDistance  : LREAL;
    fVelocity  : LREAL;
END_VAR
(* Method: MoveRelative - Purpose: Compute target, validate soft limits, call MC_MoveRelative *)
(* TODO: fTarget := astAxisStatus[nAxisIndex].fActualPosition + fDistance *)
(* TODO: validate fTarget against soft limits then execute *)
END_METHOD

METHOD JogAxis
VAR_INPUT
    nAxisIndex : UINT;
    bPositive  : BOOL;
    bNegative  : BOOL;
END_VAR
(* Method: JogAxis - Purpose: Call MC_Jog in requested direction *)
(* TODO: CASE nAxisIndex: fbMcJog1(Axis:=axis1Ref, JogForward:=bPositive, JogBackwards:=bNegative, ...) *)
END_METHOD

METHOD StopAxis
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: StopAxis - Purpose: Call MC_Stop on specified axis *)
(* TODO: CASE nAxisIndex: fbMcStop1(Axis:=axis1Ref, Execute:=TRUE, Deceleration:=...) *)
END_METHOD

METHOD StopAllAxes
(* Method: StopAllAxes - Purpose: Stop all axes immediately *)
(* TODO: call StopAxis for each axis index 1 to cMAX_AXES *)
END_METHOD

METHOD ResetAxis
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: ResetAxis - Purpose: Clear axis error via MC_Reset *)
(* TODO: CASE nAxisIndex: fbMcReset1(Axis:=axis1Ref, Execute:=TRUE) *)
END_METHOD

METHOD UpdateAxisStatus
VAR_INPUT
    nAxisIndex : UINT;
END_VAR
(* Method: UpdateAxisStatus - Purpose: Read position, velocity, state from AXIS_REF *)
(* TODO: astAxisStatus[nAxisIndex].fActualPosition := axis1Ref.NcToPlc.ActPos (or axis2Ref) *)
(* TODO: populate all ST_AxisStatus fields *)
END_METHOD

END_FUNCTION_BLOCK

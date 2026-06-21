FUNCTION_BLOCK FB_TraceLogger
VAR_INPUT
    bExportTrigger  : BOOL;
    bClearBuffer    : BOOL;
END_VAR

VAR_OUTPUT
    nEventCount         : UDINT;
    nBufferUsedPercent  : UINT;
    bBufferWrapped      : BOOL;
    astRecentEvents     : ARRAY[1..20] OF ST_TraceEvent;
END_VAR

VAR
    astRingBuffer   : ARRAY[1..1000] OF ST_TraceEvent;
    astPendingQueue : ARRAY[1..50] OF ST_TraceEvent;
    nWriteIdx       : UINT := 1;
    nPendingCount   : UINT := 0;
    rtrigExport     : R_TRIG;
    rtrigClear      : R_TRIG;
END_VAR

METHOD Cyclic
VAR
    i : UINT;
    j : UINT;
    nIdx : UINT;
END_VAR
(* Method: Cyclic - Purpose: Flush pending queue to ring buffer, update recent events output *)

rtrigClear(CLK := bClearBuffer);
IF rtrigClear.Q THEN
    nWriteIdx := 1;
    nEventCount := 0;
    nPendingCount := 0;
    bBufferWrapped := FALSE;
    FOR i := 1 TO 1000 DO
        astRingBuffer[i].nEventID := 0;
    END_FOR
END_IF

(* Flush Pending Queue *)
IF nPendingCount > 0 THEN
    FOR i := 1 TO nPendingCount DO
        astRingBuffer[nWriteIdx] := astPendingQueue[i];
        nWriteIdx := nWriteIdx + 1;
        nEventCount := nEventCount + 1;

        IF nWriteIdx > 1000 THEN
            nWriteIdx := 1;
            bBufferWrapped := TRUE;
        END_IF
    END_FOR
    nPendingCount := 0;
END_IF

(* Update Recent Events Output (last 20) *)
nIdx := nWriteIdx;
FOR j := 1 TO 20 DO
    nIdx := nIdx - 1;
    IF nIdx < 1 THEN
        IF bBufferWrapped THEN
            nIdx := 1000;
        ELSE
            EXIT; (* No more entries *)
        END_IF
    END_IF
    astRecentEvents[j] := astRingBuffer[nIdx];
END_FOR

IF nEventCount < 1000 THEN
    nBufferUsedPercent := UDINT_TO_UINT((nEventCount * 100) / 1000);
ELSE
    nBufferUsedPercent := 100;
END_IF

END_METHOD

METHOD LogEvent
VAR_INPUT
    eSource         : E_TraceSource;
    nEventID        : UINT;
    sDescription    : STRING(120);
    fValue          : LREAL;
END_VAR
(* Method: LogEvent - Purpose: Add event to pending queue with timestamp *)
IF nPendingCount < 50 THEN
    nPendingCount := nPendingCount + 1;
    astPendingQueue[nPendingCount].eSource := eSource;
    astPendingQueue[nPendingCount].nEventID := nEventID;
    astPendingQueue[nPendingCount].sDescription := sDescription;
    astPendingQueue[nPendingCount].fValue := fValue;
    (* tTimestamp would be set here if DT available *)
END_IF
END_METHOD

END_FUNCTION_BLOCK

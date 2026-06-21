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
    nWriteIdx       : UINT;
    nPendingCount   : UINT;
    rtrigExport     : R_TRIG;
    rtrigClear      : R_TRIG;
END_VAR

METHOD Cyclic
(* Method: Cyclic - Purpose: Flush pending queue to ring buffer, update recent events output *)
(* TODO: flush astPendingQueue entries to astRingBuffer, increment nWriteIdx with wraparound *)
(* TODO: copy last 20 entries to astRecentEvents *)
(* TODO: nBufferUsedPercent := (nEventCount * 100) / cTRACE_BUFFER_SIZE, clamped to 100 *)
(* TODO: if bClearBuffer rising edge: clear buffer, reset indices *)
(* TODO: if bExportTrigger rising edge: mark buffer ready for HMI or file export *)
END_METHOD

METHOD LogEvent
VAR_INPUT
    eSource         : E_TraceSource;
    nEventID        : UINT;
    sDescription    : STRING(120);
    fValue          : LREAL;
END_VAR
(* Method: LogEvent - Purpose: Add event to pending queue with timestamp *)
(* TODO: IF nPendingCount < cTRACE_PENDING_MAX THEN add to astPendingQueue, nPendingCount++ END_IF *)
(* TODO: stEntry.tTimestamp := NOW_DT() *)
END_METHOD

METHOD GetRecentEvents : ARRAY[1..20] OF ST_TraceEvent
VAR_INPUT
    nCount : UINT;
END_VAR
(* Method: GetRecentEvents - Purpose: Return last N events from ring buffer *)
(* TODO: copy last nCount entries starting from nWriteIdx working backward *)
END_METHOD

END_FUNCTION_BLOCK

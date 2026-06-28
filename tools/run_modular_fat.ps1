param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string] $TargetNetId = '',
    [int] $TargetPort = 852,
    [int] $TimeoutSeconds = 180,
    [int] $PollMilliseconds = 20,
    [switch] $SkipReset,
    [switch] $SkipRestartValidation
)

$ErrorActionPreference = 'Stop'
$expectedTests = 16

function Get-ModeName {
    param([int] $Value)
    switch ($Value) {
        0 { 'OFF' }
        1 { 'INIT' }
        2 { 'HOMING' }
        3 { 'MANUAL_JOG' }
        4 { 'AUTO' }
        5 { 'FAULT' }
        6 { 'RESET' }
        default { "UNKNOWN_$Value" }
    }
}

function Get-AxisStateName {
    param([int] $Value)
    switch ($Value) {
        0 { 'DISABLED' }
        1 { 'STANDSTILL' }
        2 { 'HOMING' }
        3 { 'DISCRETE_MOTION' }
        4 { 'CONTINUOUS_MOTION' }
        5 { 'STOPPING' }
        6 { 'ERRORSTOP' }
        default { "UNKNOWN_$Value" }
    }
}

function Get-CommandStatusName {
    param([int] $Value)
    switch ($Value) {
        0 { 'IDLE' }
        1 { 'PENDING' }
        2 { 'EXECUTING' }
        3 { 'DONE' }
        4 { 'ERROR' }
        default { "UNKNOWN_$Value" }
    }
}

function New-VariableHandles {
    param(
        $Client,
        [System.Collections.Specialized.OrderedDictionary] $Types
    )

    $result = @{}
    try {
        foreach ($symbol in $Types.Keys) {
            $result[$symbol] = $Client.CreateVariableHandle($symbol)
        }
        return $result
    }
    catch {
        foreach ($handle in $result.Values) {
            try { $Client.DeleteVariableHandle($handle) }
            catch { }
        }
        throw
    }
}

function Remove-VariableHandles {
    param(
        $Client,
        [hashtable] $Handles
    )

    foreach ($handle in $Handles.Values) {
        try { $Client.DeleteVariableHandle($handle) }
        catch { }
    }
    $Handles.Clear()
}

function Wait-ForAdsState {
    param(
        $Client,
        [string] $ExpectedState,
        [int] $TimeoutMilliseconds = 5000
    )

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $state = $Client.ReadState()
        if ($state.AdsState.ToString() -eq $ExpectedState) {
            return $state
        }
        Start-Sleep -Milliseconds 100
    } while ($timer.ElapsedMilliseconds -lt $TimeoutMilliseconds)

    throw "ADS state did not reach $ExpectedState within $TimeoutMilliseconds ms; " +
        "last state was $($state.AdsState)."
}

function Read-RuntimeSnapshot {
    param(
        $Client,
        [hashtable] $Handles,
        [System.Collections.Specialized.OrderedDictionary] $Types
    )

    $snapshot = [ordered] @{
        TimestampUtc = [DateTime]::UtcNow.ToString('o')
    }
    foreach ($symbol in $Types.Keys) {
        $column = $symbol.Substring('MAIN.'.Length)
        $snapshot[$column] = $Client.ReadAny($Handles[$symbol], $Types[$symbol])
    }
    return [pscustomobject] $snapshot
}

function Convert-SnapshotForEvidence {
    param(
        [pscustomobject] $Snapshot,
        [string] $AdsState
    )

    return [pscustomobject] ([ordered] @{
        timestampUtc = $Snapshot.TimestampUtc
        adsState = $AdsState
        simulationMode = [bool] $Snapshot.bSimulationModeActive
        simulationRunning = [bool] $Snapshot.bSimulationRunning
        simulationComplete = [bool] $Snapshot.bSimulationComplete
        testsRun = [int] $Snapshot.nTestsRun
        testsPassed = [int] $Snapshot.nTestsPassed
        testsFailed = [int] $Snapshot.nTestsFailed
        modeCode = [int] $Snapshot.eCurrentMode
        mode = Get-ModeName ([int] $Snapshot.eCurrentMode)
        axisStateCode = [int] $Snapshot.eAxis1State
        axisState = Get-AxisStateName ([int] $Snapshot.eAxis1State)
        inMotion = [bool] $Snapshot.bAxis1InMotion
        axisError = [bool] $Snapshot.bAxis1Error
        axisErrorCode = [uint32] $Snapshot.nAxis1ErrorCode
        activeAlarmCount = [int] $Snapshot.nActiveAlarmCount
        primaryAlarmId = [int] $Snapshot.nPrimaryAlarmID
        position = [double] $Snapshot.fActualPosition
        velocity = [double] $Snapshot.fActualVelocity
    })
}

function Get-StateTransitions {
    param(
        [object[]] $TestSamples,
        [string] $Property,
        [scriptblock] $NameResolver
    )

    $transitions = @()
    $previousValue = $null
    foreach ($sample in $TestSamples) {
        $currentValue = [int] $sample.$Property
        if (($null -eq $previousValue) -or ($currentValue -ne $previousValue)) {
            $fromName = if ($null -eq $previousValue) {
                'NOT_CAPTURED'
            }
            else {
                & $NameResolver ([int] $previousValue)
            }
            $transitions += [pscustomobject] ([ordered] @{
                timestampUtc = $sample.TimestampUtc
                elapsedSeconds = [double] $sample.ElapsedSeconds
                from = $fromName
                to = (& $NameResolver $currentValue)
                toCode = $currentValue
            })
            $previousValue = $currentValue
        }
    }
    return $transitions
}

$adsAssembly = Get-ChildItem `
    (Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\TwinCAT.Ads') `
    -Recurse -Filter 'TwinCAT.Ads.dll' -File |
    Sort-Object {
        try { [version] $_.VersionInfo.FileVersion }
        catch { [version] '0.0.0.0' }
    } -Descending |
    Select-Object -First 1

if ($null -eq $adsAssembly) {
    throw 'TwinCAT.Ads.dll was not found in the .NET GAC.'
}

Add-Type -Path $adsAssembly.FullName

$evidenceDirectory = Join-Path $RepositoryRoot 'simulation\test_runs'
$csvPath = Join-Path $evidenceDirectory 'MotionSafetyBench_Modular_FAT_Run02.csv'
$summaryPath = Join-Path $evidenceDirectory 'MotionSafetyBench_Modular_FAT_Run02.json'
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null

$symbolTypes = [ordered] @{
    'MAIN.bRunAutomatedTests' = [bool]
    'MAIN.bSimulationRunning' = [bool]
    'MAIN.bSimulationComplete' = [bool]
    'MAIN.bSimulationPassed' = [bool]
    'MAIN.nCurrentTest' = [uint16]
    'MAIN.nTestsRun' = [uint16]
    'MAIN.nTestsPassed' = [uint16]
    'MAIN.nTestsFailed' = [uint16]
    'MAIN.fActualPosition' = [double]
    'MAIN.fActualVelocity' = [double]
    'MAIN.eCurrentMode' = [int16]
    'MAIN.eAxis1State' = [int16]
    'MAIN.eLastCommandStatus' = [int16]
    'MAIN.bSimulationModeActive' = [bool]
    'MAIN.bAxis1InMotion' = [bool]
    'MAIN.bAxis1Error' = [bool]
    'MAIN.nAxis1ErrorCode' = [uint32]
    'MAIN.nActiveAlarmCount' = [uint16]
    'MAIN.nPrimaryAlarmID' = [uint16]
    'MAIN.nSafetyStatusWord' = [uint16]
}

$client = New-Object TwinCAT.Ads.TcAdsClient
$handles = @{}
$samples = New-Object System.Collections.Generic.List[object]
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completed = $false
$warmRestart = $null
$coldRestart = $null

try {
    if ([string]::IsNullOrWhiteSpace($TargetNetId)) {
        $client.Connect($TargetPort)
        $targetLabel = "local:$TargetPort"
    }
    else {
        $client.Connect($TargetNetId, $TargetPort)
        $targetLabel = "$TargetNetId`:$TargetPort"
    }

    $handles = New-VariableHandles -Client $client -Types $symbolTypes
    $preflight = Read-RuntimeSnapshot -Client $client -Handles $handles -Types $symbolTypes
    if (-not $preflight.bSimulationModeActive) {
        throw 'Restart validation is permitted only while the PLC is in simulation mode.'
    }

    if (-not $SkipReset) {
        Remove-VariableHandles -Client $client -Handles $handles
        $client.WriteControl(
            [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Reset, [int16] 0)
        )
        Start-Sleep -Milliseconds 500
        $client.WriteControl(
            [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Run, [int16] 0)
        )
        Wait-ForAdsState -Client $client -ExpectedState 'Run' | Out-Null
        Start-Sleep -Milliseconds 500
        $handles = New-VariableHandles -Client $client -Types $symbolTypes
    }

    $adsState = $client.ReadState()
    if ($adsState.AdsState.ToString() -eq 'Stop') {
        $client.WriteControl(
            [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Run, [int16] 0)
        )
        $adsState = Wait-ForAdsState -Client $client -ExpectedState 'Run'
        Start-Sleep -Milliseconds 500
    }
    if ($adsState.AdsState.ToString() -ne 'Run') {
        throw "PLC runtime is not in ADS Run state: $($adsState.AdsState)"
    }

    $postResetPreflight = Read-RuntimeSnapshot `
        -Client $client -Handles $handles -Types $symbolTypes
    if (-not $postResetPreflight.bSimulationModeActive) {
        throw 'PLC left simulation mode after reset; FAT was not started.'
    }

    $client.WriteAny($handles['MAIN.bRunAutomatedTests'], $false)
    Start-Sleep -Milliseconds 150
    $client.WriteAny($handles['MAIN.bRunAutomatedTests'], $true)
    Start-Sleep -Milliseconds 150
    $client.WriteAny($handles['MAIN.bRunAutomatedTests'], $false)

    Write-Output "Started modular FAT on $targetLabel."

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $sample = [ordered] @{
            ElapsedSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
            TimestampUtc = [DateTime]::UtcNow.ToString('o')
        }

        foreach ($symbol in $symbolTypes.Keys) {
            if ($symbol -eq 'MAIN.bRunAutomatedTests') {
                continue
            }
            $column = $symbol.Substring('MAIN.'.Length)
            $sample[$column] = $client.ReadAny($handles[$symbol], $symbolTypes[$symbol])
        }

        $samples.Add([pscustomobject] $sample)

        if ($sample.bSimulationComplete) {
            $completed = $true
            break
        }

        Start-Sleep -Milliseconds $PollMilliseconds
    }

    $samples | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

    if ($samples.Count -eq 0) {
        throw 'No ADS samples were captured.'
    }

    $last = $samples[$samples.Count - 1]
    $suitePassed = $completed -and
        $last.bSimulationPassed -and
        ($last.nTestsRun -eq $expectedTests) -and
        ($last.nTestsPassed -eq $expectedTests) -and
        ($last.nTestsFailed -eq 0)

    $testResults = New-Object System.Collections.Generic.List[object]
    for ($testIndex = 1; $testIndex -le $expectedTests; $testIndex++) {
        $testFields = [ordered] @{}
        foreach ($field in @(
            @{ Name = 'nTestID'; Type = [uint16] },
            @{ Name = 'eResult'; Type = [int16] },
            @{ Name = 'tDuration'; Type = [uint32] }
        )) {
            $symbol = "MAIN.fbTest.astTestSummary[$testIndex].$($field.Name)"
            $handle = $client.CreateVariableHandle($symbol)
            try {
                $testFields[$field.Name] = $client.ReadAny($handle, $field.Type)
            }
            finally {
                $client.DeleteVariableHandle($handle)
            }
        }
        foreach ($field in @(
            @{ Name = 'sTestName'; Length = 81 },
            @{ Name = 'sExpected'; Length = 121 },
            @{ Name = 'sActual'; Length = 121 }
        )) {
            $symbol = "MAIN.fbTest.astTestSummary[$testIndex].$($field.Name)"
            $handle = $client.CreateVariableHandle($symbol)
            try {
                $testFields[$field.Name] = $client.ReadAny(
                    $handle,
                    [string],
                    @($field.Length)
                )
            }
            finally {
                $client.DeleteVariableHandle($handle)
            }
        }

        $resultText = switch ($testFields.eResult) {
            2 { 'PASS' }
            3 { 'FAIL' }
            4 { 'TIMEOUT' }
            default { 'NOT_RUN' }
        }

        $testSamples = @($samples | Where-Object {
            [int] $_.nCurrentTest -eq $testIndex
        })
        if ($testSamples.Count -gt 0) {
            $firstTestSample = $testSamples[0]
            $lastTestSample = $testSamples[$testSamples.Count - 1]
            $positionMeasure = $testSamples |
                Measure-Object -Property fActualPosition -Minimum -Maximum
            $maxAlarmMeasure = $testSamples |
                Measure-Object -Property nActiveAlarmCount -Maximum
            $peakAbsVelocity = 0.0
            $travelDistance = 0.0
            $previousPosition = $null
            foreach ($testSample in $testSamples) {
                $absoluteVelocity = [math]::Abs([double] $testSample.fActualVelocity)
                if ($absoluteVelocity -gt $peakAbsVelocity) {
                    $peakAbsVelocity = $absoluteVelocity
                }
                if ($null -ne $previousPosition) {
                    $travelDistance += [math]::Abs(
                        ([double] $testSample.fActualPosition) - $previousPosition
                    )
                }
                $previousPosition = [double] $testSample.fActualPosition
            }
            $alarmIDs = @($testSamples |
                Where-Object { [int] $_.nPrimaryAlarmID -gt 0 } |
                ForEach-Object { [int] $_.nPrimaryAlarmID } |
                Sort-Object -Unique)
            $safetyWords = @($testSamples |
                ForEach-Object { [int] $_.nSafetyStatusWord } |
                Sort-Object -Unique)
            $modeTransitions = @(Get-StateTransitions `
                -TestSamples $testSamples `
                -Property 'eCurrentMode' `
                -NameResolver ${function:Get-ModeName})
            $axisTransitions = @(Get-StateTransitions `
                -TestSamples $testSamples `
                -Property 'eAxis1State' `
                -NameResolver ${function:Get-AxisStateName})
            $commandTransitions = @(Get-StateTransitions `
                -TestSamples $testSamples `
                -Property 'eLastCommandStatus' `
                -NameResolver ${function:Get-CommandStatusName})
            $recoveryObserved = ($resultText -eq 'PASS') -and
                (-not [bool] $lastTestSample.bAxis1InMotion) -and
                ([math]::Abs([double] $lastTestSample.fActualVelocity) -le 0.01)
        }
        else {
            $firstTestSample = $null
            $lastTestSample = $null
            $positionMeasure = $null
            $maxAlarmMeasure = $null
            $peakAbsVelocity = 0.0
            $travelDistance = 0.0
            $alarmIDs = @()
            $safetyWords = @()
            $modeTransitions = @()
            $axisTransitions = @()
            $commandTransitions = @()
            $recoveryObserved = $false
        }

        $testResults.Add([pscustomobject] ([ordered] @{
            testId = [int] $testFields.nTestID
            name = [string] $testFields.sTestName
            result = $resultText
            resultCode = [int] $testFields.eResult
            expected = [string] $testFields.sExpected
            actual = [string] $testFields.sActual
            startedUtc = if ($null -ne $firstTestSample) {
                $firstTestSample.TimestampUtc
            }
            else { $null }
            completedUtc = if ($null -ne $lastTestSample) {
                $lastTestSample.TimestampUtc
            }
            else { $null }
            durationMs = [int64] $testFields.tDuration
            sampleCount = $testSamples.Count
            stateTransitions = [pscustomobject] ([ordered] @{
                mode = $modeTransitions
                axis1 = $axisTransitions
                command = $commandTransitions
            })
            alarmsObserved = [pscustomobject] ([ordered] @{
                ids = $alarmIDs
                maxActiveCount = if ($null -ne $maxAlarmMeasure) {
                    [int] $maxAlarmMeasure.Maximum
                }
                else { 0 }
                clearedAtEnd = if ($null -ne $lastTestSample) {
                    [int] $lastTestSample.nActiveAlarmCount -eq 0
                }
                else { $false }
            })
            recovery = [pscustomobject] ([ordered] @{
                observed = $recoveryObserved
                finalMode = if ($null -ne $lastTestSample) {
                    Get-ModeName ([int] $lastTestSample.eCurrentMode)
                }
                else { 'NOT_CAPTURED' }
                finalAxisState = if ($null -ne $lastTestSample) {
                    Get-AxisStateName ([int] $lastTestSample.eAxis1State)
                }
                else { 'NOT_CAPTURED' }
                finalAlarmCount = if ($null -ne $lastTestSample) {
                    [int] $lastTestSample.nActiveAlarmCount
                }
                else { 0 }
                finalInMotion = if ($null -ne $lastTestSample) {
                    [bool] $lastTestSample.bAxis1InMotion
                }
                else { $false }
                finalVelocity = if ($null -ne $lastTestSample) {
                    [double] $lastTestSample.fActualVelocity
                }
                else { 0.0 }
            })
            motionMetrics = [pscustomobject] ([ordered] @{
                startPosition = if ($null -ne $firstTestSample) {
                    [double] $firstTestSample.fActualPosition
                }
                else { 0.0 }
                endPosition = if ($null -ne $lastTestSample) {
                    [double] $lastTestSample.fActualPosition
                }
                else { 0.0 }
                minimumPosition = if ($null -ne $positionMeasure) {
                    [double] $positionMeasure.Minimum
                }
                else { 0.0 }
                maximumPosition = if ($null -ne $positionMeasure) {
                    [double] $positionMeasure.Maximum
                }
                else { 0.0 }
                travelDistance = [math]::Round($travelDistance, 3)
                peakAbsoluteVelocity = [math]::Round($peakAbsVelocity, 3)
                safetyStatusWords = $safetyWords
            })
            runtimeRestart = $null
        }))
    }

    if (-not $SkipRestartValidation) {
        try {
            $warmBefore = Read-RuntimeSnapshot `
                -Client $client -Handles $handles -Types $symbolTypes
            $warmRequestedUtc = [DateTime]::UtcNow.ToString('o')
            $client.WriteControl(
                [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Stop, [int16] 0)
            )
            $stopState = Wait-ForAdsState -Client $client -ExpectedState 'Stop'
            $client.WriteControl(
                [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Run, [int16] 0)
            )
            $warmRunState = Wait-ForAdsState -Client $client -ExpectedState 'Run'
            Start-Sleep -Milliseconds 500
            $warmAfter = Read-RuntimeSnapshot `
                -Client $client -Handles $handles -Types $symbolTypes
            $warmPassed =
                ([int] $warmBefore.nTestsRun -eq $expectedTests) -and
                ([int] $warmAfter.nTestsRun -eq [int] $warmBefore.nTestsRun) -and
                ([int] $warmAfter.nTestsPassed -eq [int] $warmBefore.nTestsPassed) -and
                ([bool] $warmAfter.bSimulationComplete) -and
                (-not [bool] $warmAfter.bAxis1InMotion) -and
                ([math]::Abs([double] $warmAfter.fActualVelocity) -le 0.01)
            $warmRestart = [pscustomobject] ([ordered] @{
                type = 'warm'
                controlSequence = 'ADS Stop -> ADS Run'
                requestedUtc = $warmRequestedUtc
                stoppedState = $stopState.AdsState.ToString()
                resumedState = $warmRunState.AdsState.ToString()
                passed = $warmPassed
                acceptance = 'Counters preserved; no stale motion after resume'
                before = Convert-SnapshotForEvidence `
                    -Snapshot $warmBefore -AdsState 'Run'
                after = Convert-SnapshotForEvidence `
                    -Snapshot $warmAfter -AdsState $warmRunState.AdsState.ToString()
                error = $null
            })
        }
        catch {
            $warmRestart = [pscustomobject] ([ordered] @{
                type = 'warm'
                controlSequence = 'ADS Stop -> ADS Run'
                requestedUtc = [DateTime]::UtcNow.ToString('o')
                stoppedState = $null
                resumedState = $null
                passed = $false
                acceptance = 'Counters preserved; no stale motion after resume'
                before = $null
                after = $null
                error = $_.Exception.Message
            })
        }

        try {
            Remove-VariableHandles -Client $client -Handles $handles
            $coldRequestedUtc = [DateTime]::UtcNow.ToString('o')
            $client.WriteControl(
                [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Reset, [int16] 0)
            )
            Start-Sleep -Milliseconds 500
            $resetState = $client.ReadState()
            $client.WriteControl(
                [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Run, [int16] 0)
            )
            $coldRunState = Wait-ForAdsState -Client $client -ExpectedState 'Run'
            Start-Sleep -Milliseconds 500
            $handles = New-VariableHandles -Client $client -Types $symbolTypes
            $coldAfter = Read-RuntimeSnapshot `
                -Client $client -Handles $handles -Types $symbolTypes
            $coldPassed =
                ([bool] $coldAfter.bSimulationModeActive) -and
                (-not [bool] $coldAfter.bSimulationRunning) -and
                (-not [bool] $coldAfter.bSimulationComplete) -and
                ([int] $coldAfter.nTestsRun -eq 0) -and
                ([int] $coldAfter.nTestsPassed -eq 0) -and
                ([int] $coldAfter.nTestsFailed -eq 0) -and
                (-not [bool] $coldAfter.bAxis1InMotion) -and
                ([math]::Abs([double] $coldAfter.fActualVelocity) -le 0.01) -and
                ([int] $coldAfter.nActiveAlarmCount -eq 0)
            $coldRestart = [pscustomobject] ([ordered] @{
                type = 'cold'
                controlSequence = 'ADS Reset -> ADS Run'
                requestedUtc = $coldRequestedUtc
                resetState = $resetState.AdsState.ToString()
                resumedState = $coldRunState.AdsState.ToString()
                passed = $coldPassed
                acceptance = 'Initialized counters, alarms and motion state restored'
                after = Convert-SnapshotForEvidence `
                    -Snapshot $coldAfter -AdsState $coldRunState.AdsState.ToString()
                error = $null
            })
        }
        catch {
            $coldRestart = [pscustomobject] ([ordered] @{
                type = 'cold'
                controlSequence = 'ADS Reset -> ADS Run'
                requestedUtc = [DateTime]::UtcNow.ToString('o')
                resetState = $null
                resumedState = $null
                passed = $false
                acceptance = 'Initialized counters, alarms and motion state restored'
                after = $null
                error = $_.Exception.Message
            })
        }
    }
    else {
        $warmRestart = [pscustomobject] ([ordered] @{
            type = 'warm'
            controlSequence = 'SKIPPED'
            passed = $false
            error = 'Restart validation was explicitly skipped.'
        })
        $coldRestart = [pscustomobject] ([ordered] @{
            type = 'cold'
            controlSequence = 'SKIPPED'
            passed = $false
            error = 'Restart validation was explicitly skipped.'
        })
    }

    $testResults[12].runtimeRestart = $warmRestart
    $testResults[13].runtimeRestart = $coldRestart
    $restartValidationPassed = $warmRestart.passed -and $coldRestart.passed
    $passed = $suitePassed -and $restartValidationPassed
    $finalAdsState = $client.ReadState()

    $summary = [ordered] @{
        runId = 'MotionSafetyBench_Modular_FAT_Run02'
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        targetNetId = if ([string]::IsNullOrWhiteSpace($TargetNetId)) {
            'local'
        }
        else {
            $TargetNetId
        }
        targetPort = $TargetPort
        adsState = $finalAdsState.AdsState.ToString()
        suiteAdsState = $adsState.AdsState.ToString()
        timeoutSeconds = $TimeoutSeconds
        elapsedSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
        sampleCount = $samples.Count
        completed = $completed
        passed = $passed
        suitePassed = $suitePassed
        restartValidationPassed = $restartValidationPassed
        testsRun = [int] $last.nTestsRun
        testsPassed = [int] $last.nTestsPassed
        testsFailed = [int] $last.nTestsFailed
        finalTest = [int] $last.nCurrentTest
        finalMode = [int] $last.eCurrentMode
        finalPosition = [double] $last.fActualPosition
        finalVelocity = [double] $last.fActualVelocity
        evidenceCsv = 'simulation/test_runs/MotionSafetyBench_Modular_FAT_Run02.csv'
        restartValidation = @($warmRestart, $coldRestart)
        tests = $testResults
    }
    $summary | ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $summaryPath -Encoding UTF8

    Write-Output "Completed: $completed"
    Write-Output "Suite passed: $suitePassed"
    Write-Output "Restart validation passed: $restartValidationPassed"
    Write-Output "Passed: $passed"
    Write-Output "Tests: $($last.nTestsPassed)/$($last.nTestsRun), failed $($last.nTestsFailed)"
    Write-Output "Evidence: $csvPath"
    Write-Output "Summary: $summaryPath"

    if (-not $passed) {
        throw "Modular FAT acceptance failed. Suite passed: $suitePassed; " +
            "restart validation passed: $restartValidationPassed."
    }
}
finally {
    Remove-VariableHandles -Client $client -Handles $handles
    $client.Dispose()
    $stopwatch.Stop()
}

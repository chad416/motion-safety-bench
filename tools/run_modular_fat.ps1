param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string] $TargetNetId = '',
    [int] $TargetPort = 852,
    [int] $TimeoutSeconds = 180,
    [int] $PollMilliseconds = 100,
    [switch] $SkipReset
)

$ErrorActionPreference = 'Stop'

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
}

$client = New-Object TwinCAT.Ads.TcAdsClient
$handles = @{}
$samples = New-Object System.Collections.Generic.List[object]
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$completed = $false

try {
    if ([string]::IsNullOrWhiteSpace($TargetNetId)) {
        $client.Connect($TargetPort)
        $targetLabel = "local:$TargetPort"
    }
    else {
        $client.Connect($TargetNetId, $TargetPort)
        $targetLabel = "$TargetNetId`:$TargetPort"
    }

    if (-not $SkipReset) {
        $client.WriteControl(
            [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Reset, [int16] 0)
        )
        Start-Sleep -Milliseconds 500
        $client.WriteControl(
            [TwinCAT.Ads.StateInfo]::new([TwinCAT.Ads.AdsState]::Run, [int16] 0)
        )
        Start-Sleep -Milliseconds 500
    }

    $adsState = $client.ReadState()
    if ($adsState.AdsState.ToString() -eq 'Stop') {
        $runState = [TwinCAT.Ads.StateInfo]::new(
            [TwinCAT.Ads.AdsState]::Run,
            [int16] 0
        )
        $client.WriteControl($runState)
        Start-Sleep -Milliseconds 500
        $adsState = $client.ReadState()
    }
    if ($adsState.AdsState.ToString() -ne 'Run') {
        throw "PLC runtime is not in ADS Run state: $($adsState.AdsState)"
    }

    foreach ($symbol in $symbolTypes.Keys) {
        $handles[$symbol] = $client.CreateVariableHandle($symbol)
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

    $last = $samples[$samples.Count - 1]
    $passed = $completed -and
        $last.bSimulationPassed -and
        ($last.nTestsRun -eq 12) -and
        ($last.nTestsPassed -eq 12) -and
        ($last.nTestsFailed -eq 0)

    $testResults = New-Object System.Collections.Generic.List[object]
    for ($testIndex = 1; $testIndex -le 12; $testIndex++) {
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
        $testResults.Add([pscustomobject] ([ordered] @{
            testId = [int] $testFields.nTestID
            name = [string] $testFields.sTestName
            result = $resultText
            resultCode = [int] $testFields.eResult
            expected = [string] $testFields.sExpected
            actual = [string] $testFields.sActual
            durationMs = [int64] $testFields.tDuration
        }))
    }

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
        adsState = $adsState.AdsState.ToString()
        timeoutSeconds = $TimeoutSeconds
        elapsedSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
        sampleCount = $samples.Count
        completed = $completed
        passed = $passed
        testsRun = [int] $last.nTestsRun
        testsPassed = [int] $last.nTestsPassed
        testsFailed = [int] $last.nTestsFailed
        finalTest = [int] $last.nCurrentTest
        finalMode = [int] $last.eCurrentMode
        finalPosition = [double] $last.fActualPosition
        finalVelocity = [double] $last.fActualVelocity
        evidenceCsv = 'simulation/test_runs/MotionSafetyBench_Modular_FAT_Run02.csv'
        tests = $testResults
    }
    $summary | ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath $summaryPath -Encoding UTF8

    Write-Output "Completed: $completed"
    Write-Output "Passed: $passed"
    Write-Output "Tests: $($last.nTestsPassed)/$($last.nTestsRun), failed $($last.nTestsFailed)"
    Write-Output "Evidence: $csvPath"
    Write-Output "Summary: $summaryPath"

    if (-not $passed) {
        throw "Modular FAT did not pass. Current test $($last.nCurrentTest); " +
            "run/passed/failed $($last.nTestsRun)/$($last.nTestsPassed)/$($last.nTestsFailed)."
    }
}
finally {
    foreach ($handle in $handles.Values) {
        try { $client.DeleteVariableHandle($handle) }
        catch { }
    }
    $client.Dispose()
    $stopwatch.Stop()
}

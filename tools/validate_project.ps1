param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]
$passes = New-Object System.Collections.Generic.List[string]

function Add-Pass {
    param([string] $Message)
    $passes.Add($Message)
}

function Add-Failure {
    param([string] $Message)
    $failures.Add($Message)
}

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Success,
        [string] $Failure
    )
    if ($Condition) {
        Add-Pass $Success
    }
    else {
        Add-Failure $Failure
    }
}

Push-Location $RepositoryRoot
try {
    $requiredDocuments = @(
        'README.md',
        'docs\00_project_charter.md',
        'docs\01_URS.md',
        'docs\02_FDS.md',
        'docs\03_SDS.md',
        'docs\04_IO_list.md',
        'docs\05_network_diagram.md',
        'docs\06_alarm_list.md',
        'docs\07_cause_effect_matrix.md',
        'docs\08_FMEA.md',
        'docs\09_FAT_protocol.md',
        'docs\10_SAT_protocol.md',
        'docs\11_commissioning_logbook.md',
        'docs\12_commissioning_checklist.md',
        'docs\13_final_engineering_report.md',
        'hmi\hmi_screen_spec.md',
        'hmi\hmi_tag_map.md',
        'hardware\BOM.md',
        'hardware\procurement_risks.md',
        'hardware\wiring_plan.md',
        'portfolio\final_case_study.md',
        'portfolio\demo_script_90sec.md',
        'portfolio\engineering_walkthrough_script.md'
    )

    $missingDocuments = @($requiredDocuments | Where-Object { -not (Test-Path -LiteralPath $_) })
    Assert-True ($missingDocuments.Count -eq 0) `
        'All required engineering documents exist.' `
        ("Missing engineering documents: " + ($missingDocuments -join ', '))

    $placeholderHits = @(
        rg -n 'placeholder generated|DRAFT\s+[—-]\s+placeholder|Replace with content|\[Your name\]' `
            README.md docs hmi hardware portfolio 2>$null
    )
    Assert-True ($placeholderHits.Count -eq 0) `
        'No generated placeholder documents remain.' `
        ("Placeholder text remains: " + ($placeholderHits -join ' | '))

    $plcTodoHits = @(
        rg -n '\(\*\s*TODO\b|implementation follows' plc -g '*.st' 2>$null
    )
    Assert-True ($plcTodoHits.Count -eq 0) `
        'PLC source contains no implementation TODO markers.' `
        ("PLC implementation markers remain: " + ($plcTodoHits -join ' | '))

    $plcFiles = @(Get-ChildItem -LiteralPath 'plc' -Filter '*.st' -File)
    Assert-True ($plcFiles.Count -eq 16) `
        'Expected 16 reviewed Structured Text source files are present.' `
        "Expected 16 Structured Text files; found $($plcFiles.Count)."

    $nativeRoot = 'twincat\RuntimeSimulation'
    $dutFiles = @(Get-ChildItem -LiteralPath (Join-Path $nativeRoot 'DUTs') -Filter '*.TcDUT' -File)
    $gvlFiles = @(Get-ChildItem -LiteralPath (Join-Path $nativeRoot 'GVLs') -Filter '*.TcGVL' -File)
    $pouFiles = @(Get-ChildItem -LiteralPath (Join-Path $nativeRoot 'POUs') -Filter '*.TcPOU' -File)

    Assert-True ($dutFiles.Count -eq 26) `
        'Generated TwinCAT project contains 26 native DUT objects.' `
        "Expected 26 native DUT objects; found $($dutFiles.Count)."
    Assert-True ($gvlFiles.Count -eq 3) `
        'Generated TwinCAT project contains 3 native GVL objects.' `
        "Expected 3 native GVL objects; found $($gvlFiles.Count)."
    Assert-True ($pouFiles.Count -eq 11) `
        'Generated TwinCAT project contains 11 native POU objects.' `
        "Expected 11 native POU objects; found $($pouFiles.Count)."

    $nativeFiles = @($dutFiles + $gvlFiles + $pouFiles)
    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($file in $nativeFiles) {
        try {
            [xml] $xml = Get-Content -LiteralPath $file.FullName -Raw
            $node = $xml.TcPlcObject.ChildNodes |
                Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element } |
                Select-Object -First 1
            if ($null -eq $node -or [string]::IsNullOrWhiteSpace($node.Id)) {
                Add-Failure "Native object has no ID: $($file.FullName)"
            }
            else {
                $ids.Add([string] $node.Id)
            }
        }
        catch {
            Add-Failure "Invalid TwinCAT XML: $($file.FullName): $($_.Exception.Message)"
        }
    }
    Assert-True (($ids | Select-Object -Unique).Count -eq $ids.Count) `
        'All generated TwinCAT object IDs are unique.' `
        'Duplicate generated TwinCAT object IDs were detected.'

    $projectPath = Join-Path $nativeRoot 'MotionSafetyBenchPLC.plcproj'
    $projectText = Get-Content -LiteralPath $projectPath -Raw
    $compileMatches = [regex]::Matches($projectText, '<Compile Include="([^"]+)"')
    $missingCompileItems = New-Object System.Collections.Generic.List[string]
    foreach ($match in $compileMatches) {
        $itemPath = Join-Path $nativeRoot $match.Groups[1].Value
        if (-not (Test-Path -LiteralPath $itemPath)) {
            $missingCompileItems.Add($match.Groups[1].Value)
        }
    }
    Assert-True ($missingCompileItems.Count -eq 0) `
        'Every TwinCAT project Compile item resolves to a file.' `
        ("Missing Compile items: " + ($missingCompileItems -join ', '))
    Assert-True ($compileMatches.Count -eq 41) `
        'TwinCAT project contains the expected 41 compile items.' `
        "Expected 41 compile items; found $($compileMatches.Count)."

    [xml] $taskXml = Get-Content -LiteralPath (Join-Path $nativeRoot 'PlcTask.TcTTO') -Raw
    Assert-True ($taskXml.TcPlcObject.Task.PouCall.Name -eq 'MAIN') `
        'PLC task calls MAIN.' `
        "PLC task calls '$($taskXml.TcPlcObject.Task.PouCall.Name)' instead of MAIN."
    Assert-True ([int] $taskXml.TcPlcObject.Task.CycleTime -eq 10000) `
        'PLC task cycle is 10 ms.' `
        'PLC task cycle is not 10 ms.'

    $runtimeSolutionPath = 'twincat\MotionSafetyBenchRuntime.sln'
    $runtimeSystemPath = 'twincat\RuntimeSystem\MotionSafetyBench.tsproj'
    Assert-True (Test-Path -LiteralPath $runtimeSolutionPath) `
        'Complete TwinCAT runtime solution exists.' `
        'Complete TwinCAT runtime solution is missing.'
    Assert-True (Test-Path -LiteralPath $runtimeSystemPath) `
        'TwinCAT runtime system project exists.' `
        'TwinCAT runtime system project is missing.'
    if (Test-Path -LiteralPath $runtimeSystemPath) {
        $runtimeSystemText = Get-Content -LiteralPath $runtimeSystemPath -Raw
        Assert-True (
            ($runtimeSystemText -match 'AmsPort="852"') -and
            ($runtimeSystemText -match '\.\.\\RuntimeSimulation\\MotionSafetyBenchPLC\.plcproj')
        ) `
            'Runtime system references the generated PLC on ADS port 852.' `
            'Runtime system PLC reference or ADS port is incorrect.'
        Assert-True ($runtimeSystemText -notmatch 'C:\\Users\\') `
            'Runtime system contains no user-specific absolute paths.' `
            'Runtime system contains a user-specific absolute path.'
    }

    $csvPath = 'simulation\test_runs\MotionSafetyBench_Simulation_Run01.csv'
    $plotPath = 'simulation\test_runs\MotionSafetyBench_Simulation_Run01.png'
    $modularCsvPath = 'simulation\test_runs\MotionSafetyBench_Modular_FAT_Run02.csv'
    $modularJsonPath = 'simulation\test_runs\MotionSafetyBench_Modular_FAT_Run02.json'
    $modularPlotPath = 'simulation\test_runs\MotionSafetyBench_Modular_FAT_Run02.png'
    $workbookPath = 'outputs\motion-safety-bench\MotionSafetyBench_Simulation_Evidence.xlsx'
    Assert-True (Test-Path -LiteralPath $csvPath) `
        'Scope CSV evidence exists.' `
        'Scope CSV evidence is missing.'
    Assert-True (Test-Path -LiteralPath $plotPath) `
        'Scope motion plot exists.' `
        'Scope motion plot is missing.'
    Assert-True (Test-Path -LiteralPath $workbookPath) `
        'Simulation evidence workbook exists.' `
        'Simulation evidence workbook is missing.'
    Assert-True (Test-Path -LiteralPath $modularCsvPath) `
        'Modular FAT ADS CSV evidence exists.' `
        'Modular FAT ADS CSV evidence is missing.'
    Assert-True (Test-Path -LiteralPath $modularJsonPath) `
        'Modular FAT JSON summary exists.' `
        'Modular FAT JSON summary is missing.'
    Assert-True (Test-Path -LiteralPath $modularPlotPath) `
        'Modular FAT motion plot exists.' `
        'Modular FAT motion plot is missing.'

    if (Test-Path -LiteralPath $modularJsonPath) {
        $modularSummary = Get-Content -LiteralPath $modularJsonPath -Raw |
            ConvertFrom-Json
        Assert-True (
            $modularSummary.completed -and
            $modularSummary.passed -and
            ($modularSummary.testsRun -eq 16) -and
            ($modularSummary.testsPassed -eq $modularSummary.testsRun) -and
            ($modularSummary.testsFailed -eq 0)
        ) `
            'Modular FAT summary records the complete 16-test passing suite and zero failed.' `
            'Modular FAT summary is not the accepted 16-test passing suite.'
        Assert-True (
            ($modularSummary.adsState -eq 'Run') -and
            ($modularSummary.targetPort -eq 852) -and
            ($modularSummary.tests.Count -eq $modularSummary.testsRun)
        ) `
            'Modular FAT summary identifies ADS Run on port 852 with matching test records.' `
            'Modular FAT target state, port or detailed test count is incorrect.'
    }

    if (Test-Path -LiteralPath $csvPath) {
        $numericRows = @(
            Get-Content -LiteralPath $csvPath |
                Where-Object { $_ -match '^\d+\t-?\d+(?:[\.,]\d+)?\t\d+\t-?\d+(?:[\.,]\d+)?$' }
        )
        $positions = New-Object System.Collections.Generic.List[double]
        $velocities = New-Object System.Collections.Generic.List[double]
        foreach ($line in $numericRows) {
            $parts = $line -split "`t"
            $positions.Add([double] ($parts[1] -replace ',', '.'))
            $velocities.Add([double] ($parts[3] -replace ',', '.'))
        }
        $positionStats = $positions | Measure-Object -Minimum -Maximum
        $velocityStats = $velocities | Measure-Object -Minimum -Maximum
        $movingSamples = @($velocities | Where-Object { $_ -ne 0 }).Count

        Assert-True ($numericRows.Count -eq 25445) `
            'Scope CSV contains 25,445 samples.' `
            "Scope CSV expected 25,445 samples; found $($numericRows.Count)."
        Assert-True (($positionStats.Minimum -eq 0) -and ($positionStats.Maximum -eq 215)) `
            'Scope position range is 0 to 215 mm.' `
            "Unexpected position range: $($positionStats.Minimum) to $($positionStats.Maximum)."
        Assert-True (($velocityStats.Minimum -eq 0) -and ($velocityStats.Maximum -eq 200)) `
            'Scope velocity range is 0 to 200 mm/s.' `
            "Unexpected velocity range: $($velocityStats.Minimum) to $($velocityStats.Maximum)."
        Assert-True ($movingSamples -eq 143) `
            'Scope CSV contains 143 moving samples.' `
            "Expected 143 moving samples; found $movingSamples."
    }

    $nodePath = 'C:\Program Files\nodejs\node.exe'
    if (Test-Path -LiteralPath $nodePath) {
        & $nodePath --check 'hmi\prototype\app.js' 2>&1 | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) `
            'HMI JavaScript syntax check passed.' `
            'HMI JavaScript syntax check failed.'
    }
    else {
        Add-Failure 'Node.js was not available for the HMI syntax check.'
    }

    $requiredHmiText = @(
        'Run 16-test simulation',
        'E-STOP',
        'Safety chain',
        'Position &amp; velocity'
    )
    $hmiMarkup = Get-Content -LiteralPath 'hmi\prototype\index.html' -Raw
    $missingHmiText = @($requiredHmiText | Where-Object { $hmiMarkup -notmatch [regex]::Escape($_) })
    Assert-True ($missingHmiText.Count -eq 0) `
        'HMI contains required operator controls and status elements.' `
        ("HMI is missing: " + ($missingHmiText -join ', '))

    $powerShellScripts = @(
        'tools\generate_twincat_project.ps1',
        'tools\build_twincat_solution.ps1',
        'tools\deploy_twincat_runtime.ps1',
        'tools\run_modular_fat.ps1',
        'tools\validate_project.ps1'
    )
    $scriptSyntaxFailures = New-Object System.Collections.Generic.List[string]
    foreach ($scriptPath in $powerShellScripts) {
        try {
            [void] [scriptblock]::Create(
                (Get-Content -LiteralPath $scriptPath -Raw)
            )
        }
        catch {
            $scriptSyntaxFailures.Add("${scriptPath}: $($_.Exception.Message)")
        }
    }
    Assert-True ($scriptSyntaxFailures.Count -eq 0) `
        'Core PowerShell automation scripts pass syntax parsing.' `
        ("PowerShell syntax failures: " + ($scriptSyntaxFailures -join ' | '))

    $checksumPath = 'simulation\test_runs\SHA256SUMS.txt'
    $checksumFailures = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $checksumPath) {
        $checksumDirectory = Split-Path -Parent $checksumPath
        foreach ($line in Get-Content -LiteralPath $checksumPath) {
            if ($line -match '^([A-Fa-f0-9]{64})\s+(.+)$') {
                $expectedHash = $Matches[1].ToUpperInvariant()
                $evidencePath = Join-Path $checksumDirectory $Matches[2]
                if (-not (Test-Path -LiteralPath $evidencePath)) {
                    $checksumFailures.Add("Missing evidence: $($Matches[2])")
                }
                else {
                    $actualHash = (
                        Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256
                    ).Hash
                    if ($actualHash -ne $expectedHash) {
                        $checksumFailures.Add("Hash mismatch: $($Matches[2])")
                    }
                }
            }
        }
    }
    else {
        $checksumFailures.Add('SHA256SUMS.txt is missing.')
    }
    Assert-True ($checksumFailures.Count -eq 0) `
        'All retained evidence files match SHA-256 records.' `
        ("Evidence checksum failures: " + ($checksumFailures -join ' | '))

    $trackedFiles = @(git ls-files)
    $forbiddenTracked = @(
        $trackedFiles | Where-Object {
            $_ -match '(^|/)routes/' -or
            $_ -match 'um_runtime_backup' -or
            $_ -match '/_Boot/' -or
            $_ -match '/_Libraries/' -or
            $_ -match '\.tclrs$'
        }
    )
    Assert-True ($forbiddenTracked.Count -eq 0) `
        'No machine-specific routes, boot files, libraries or licenses are tracked.' `
        ("Forbidden tracked artifacts: " + ($forbiddenTracked -join ', '))

    Write-Output ''
    Write-Output '=== Motion Safety Bench Validation ==='
    foreach ($pass in $passes) {
        Write-Output "[PASS] $pass"
    }
    foreach ($failure in $failures) {
        Write-Output "[FAIL] $failure"
    }
    Write-Output ''
    Write-Output "Passed checks: $($passes.Count)"
    Write-Output "Failed checks: $($failures.Count)"

    if ($failures.Count -gt 0) {
        exit 1
    }
}
finally {
    Pop-Location
}

param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $RepositoryRoot 'plc'
$projectRoot = Join-Path $RepositoryRoot 'twincat\RuntimeSimulation'
$dutRoot = Join-Path $projectRoot 'DUTs'
$gvlRoot = Join-Path $projectRoot 'GVLs'
$pouRoot = Join-Path $projectRoot 'POUs'

foreach ($directory in @($projectRoot, $dutRoot, $gvlRoot, $pouRoot)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

function Get-StableGuid {
    param([Parameter(Mandatory = $true)][string] $Name)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("motion-safety-bench/$Name"))
        $bytes = New-Object byte[] 16
        [Array]::Copy($hash, $bytes, 16)
        return (New-Object Guid (,$bytes)).ToString('B').ToUpperInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Protect-CData {
    param([Parameter(Mandatory = $true)][string] $Text)
    return $Text.Replace(']]>', ']]]]><![CDATA[>')
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Content
    )
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

function Convert-StPou {
    param([Parameter(Mandatory = $true)][string] $SourcePath)

    $lines = Get-Content -LiteralPath $SourcePath
    $firstLine = $lines[0].Trim()
    if ($firstLine -match '^FUNCTION_BLOCK\s+([A-Za-z_][A-Za-z0-9_]*)$') {
        $name = $Matches[1]
        $endMarker = 'END_FUNCTION_BLOCK'
    }
    elseif ($firstLine -match '^PROGRAM\s+([A-Za-z_][A-Za-z0-9_]*)$') {
        $name = $Matches[1]
        $endMarker = 'END_PROGRAM'
    }
    else {
        throw "Unsupported POU declaration in $SourcePath"
    }

    $endVarIndexes = for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq 'END_VAR') { $index }
    }
    if ($endVarIndexes.Count -eq 0) {
        throw "No END_VAR declaration marker found in $SourcePath"
    }
    $declarationEnd = $endVarIndexes[-1]
    $objectEnd = [Array]::LastIndexOf($lines, $endMarker)
    if ($objectEnd -le $declarationEnd) {
        throw "No $endMarker marker found after declaration in $SourcePath"
    }

    $declaration = Protect-CData (($lines[0..$declarationEnd] -join "`r`n") + "`r`n")
    $implementationLines = if ($objectEnd -gt ($declarationEnd + 1)) {
        $lines[($declarationEnd + 1)..($objectEnd - 1)]
    }
    else {
        @()
    }
    $implementation = Protect-CData ((($implementationLines -join "`r`n").Trim()) + "`r`n")
    $id = Get-StableGuid "POU/$name"
    $targetPath = Join-Path $pouRoot "$name.TcPOU"

    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<TcPlcObject Version="1.1.0.1">
  <POU Name="$name" Id="$id">
    <Declaration><![CDATA[$declaration]]></Declaration>
    <Implementation>
      <ST><![CDATA[$implementation]]></ST>
    </Implementation>
  </POU>
</TcPlcObject>
"@
    Write-Utf8File -Path $targetPath -Content $xml
    return $targetPath
}

function Convert-StDuts {
    param([Parameter(Mandatory = $true)][string] $SourcePath)

    $lines = Get-Content -LiteralPath $SourcePath
    $start = -1
    $results = @()

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if (($start -lt 0) -and ($lines[$index] -match '^TYPE\s+([A-Za-z_][A-Za-z0-9_]*)\s*:')) {
            $start = $index
            $name = $Matches[1]
        }
        elseif (($start -ge 0) -and ($lines[$index].Trim() -eq 'END_TYPE')) {
            $declaration = Protect-CData (($lines[$start..$index] -join "`r`n") + "`r`n")
            $id = Get-StableGuid "DUT/$name"
            $targetPath = Join-Path $dutRoot "$name.TcDUT"
            $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<TcPlcObject Version="1.1.0.1">
  <DUT Name="$name" Id="$id">
    <Declaration><![CDATA[$declaration]]></Declaration>
  </DUT>
</TcPlcObject>
"@
            Write-Utf8File -Path $targetPath -Content $xml
            $results += $targetPath
            $start = -1
            $name = $null
        }
    }

    if ($start -ge 0) {
        throw "Unterminated TYPE declaration in $SourcePath"
    }
    return $results
}

function Convert-StGvl {
    param([Parameter(Mandatory = $true)][string] $SourcePath)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $declaration = Protect-CData ((Get-Content -LiteralPath $SourcePath -Raw).Trim() + "`r`n")
    $id = Get-StableGuid "GVL/$name"
    $targetPath = Join-Path $gvlRoot "$name.TcGVL"
    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<TcPlcObject Version="1.1.0.1">
  <GVL Name="$name" Id="$id">
    <Declaration><![CDATA[$declaration]]></Declaration>
  </GVL>
</TcPlcObject>
"@
    Write-Utf8File -Path $targetPath -Content $xml
    return $targetPath
}

$generatedDuts = @()
$generatedDuts += Convert-StDuts (Join-Path $sourceRoot 'Enumerations.st')
$generatedDuts += Convert-StDuts (Join-Path $sourceRoot 'Structures.st')

$generatedGvls = @()
foreach ($gvlName in @('GVL_Constants.st', 'GVL_VirtualIO.st', 'GVL_IO.st')) {
    $generatedGvls += Convert-StGvl (Join-Path $sourceRoot $gvlName)
}

$generatedPous = @()
foreach ($pouName in @(
    'ConfigPackage.st',
    'SafetyManager.st',
    'AlarmManager.st',
    'ModeManager.st',
    'CommandParser.st',
    'HomingManager.st',
    'AxisManager.st',
    'TraceLogger.st',
    'HMIModel.st',
    'TestHarness.st',
    'MAIN.st'
)) {
    $generatedPous += Convert-StPou (Join-Path $sourceRoot $pouName)
}

$compileItems = @('    <Compile Include="PlcTask.TcTTO"><SubType>Code</SubType></Compile>')
foreach ($file in $generatedDuts + $generatedGvls + $generatedPous) {
    $relative = $file.Substring($projectRoot.Length + 1)
    $compileItems += "    <Compile Include=`"$relative`"><SubType>Code</SubType></Compile>"
}

$projectGuid = '{44E41B1F-1282-47A8-9246-D06D26944F39}'
$applicationGuid = Get-StableGuid 'Application'
$typeSystemGuid = Get-StableGuid 'TypeSystem'
$taskInfoGuid = Get-StableGuid 'ImplicitTaskInfo'
$kindOfTaskGuid = Get-StableGuid 'ImplicitKindOfTask'
$jitterGuid = Get-StableGuid 'ImplicitJitterDistribution'
$libraryGuid = Get-StableGuid 'LibraryReferences'

$projectXml = @"
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <FileVersion>1.0.0.0</FileVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>$projectGuid</ProjectGuid>
    <SubObjectsSortedByName>True</SubObjectsSortedByName>
    <DownloadApplicationInfo>true</DownloadApplicationInfo>
    <WriteProductVersion>true</WriteProductVersion>
    <GenerateTpy>false</GenerateTpy>
    <Name>MotionSafetyBenchPLC</Name>
    <ProgramVersion>3.1.4024.0</ProgramVersion>
    <Application>$applicationGuid</Application>
    <TypeSystem>$typeSystemGuid</TypeSystem>
    <Implicit_Task_Info>$taskInfoGuid</Implicit_Task_Info>
    <Implicit_KindOfTask>$kindOfTaskGuid</Implicit_KindOfTask>
    <Implicit_Jitter_Distribution>$jitterGuid</Implicit_Jitter_Distribution>
    <LibraryReferences>$libraryGuid</LibraryReferences>
  </PropertyGroup>
  <ItemGroup>
$($compileItems -join "`r`n")
  </ItemGroup>
  <ItemGroup>
    <Folder Include="DUTs" />
    <Folder Include="GVLs" />
    <Folder Include="POUs" />
    <Folder Include="VISUs" />
  </ItemGroup>
  <ItemGroup>
    <PlaceholderReference Include="Tc2_MC2">
      <DefaultResolution>Tc2_MC2, * (Beckhoff Automation GmbH)</DefaultResolution>
      <Namespace>Tc2_MC2</Namespace>
    </PlaceholderReference>
    <PlaceholderReference Include="Tc2_Standard">
      <DefaultResolution>Tc2_Standard, * (Beckhoff Automation GmbH)</DefaultResolution>
      <Namespace>Tc2_Standard</Namespace>
    </PlaceholderReference>
    <PlaceholderReference Include="Tc2_System">
      <DefaultResolution>Tc2_System, * (Beckhoff Automation GmbH)</DefaultResolution>
      <Namespace>Tc2_System</Namespace>
    </PlaceholderReference>
    <PlaceholderReference Include="Tc3_Module">
      <DefaultResolution>Tc3_Module, * (Beckhoff Automation GmbH)</DefaultResolution>
      <Namespace>Tc3_Module</Namespace>
    </PlaceholderReference>
  </ItemGroup>
</Project>
"@
Write-Utf8File -Path (Join-Path $projectRoot 'MotionSafetyBenchPLC.plcproj') -Content $projectXml

$taskId = Get-StableGuid 'Task/PlcTask'
$taskFbGuid = Get-StableGuid 'Task/PlcTask/Fb'
$fbInitGuid = Get-StableGuid 'Task/PlcTask/FbInit'
$fbExitGuid = Get-StableGuid 'Task/PlcTask/FbExit'
$cycleUpdateGuid = Get-StableGuid 'Task/PlcTask/CycleUpdate'
$postCycleUpdateGuid = Get-StableGuid 'Task/PlcTask/PostCycleUpdate'
$taskXml = @"
<?xml version="1.0" encoding="utf-8"?>
<TcPlcObject Version="1.1.0.1">
  <Task Name="PlcTask" Id="$taskId">
    <CycleTime>10000</CycleTime>
    <Priority>20</Priority>
    <PouCall><Name>MAIN</Name></PouCall>
    <TaskFBGuid>$taskFbGuid</TaskFBGuid>
    <Fb_init>$fbInitGuid</Fb_init>
    <Fb_exit>$fbExitGuid</Fb_exit>
    <CycleUpdate>$cycleUpdateGuid</CycleUpdate>
    <PostCycleUpdate>$postCycleUpdateGuid</PostCycleUpdate>
    <ObjectProperties />
  </Task>
</TcPlcObject>
"@
Write-Utf8File -Path (Join-Path $projectRoot 'PlcTask.TcTTO') -Content $taskXml

Write-Output "Generated $($generatedDuts.Count) DUTs, $($generatedGvls.Count) GVLs, and $($generatedPous.Count) POUs."
Write-Output (Join-Path $projectRoot 'MotionSafetyBenchPLC.plcproj')

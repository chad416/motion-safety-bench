param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('Inspect', 'Deploy', 'Update', 'Restart')]
    [string] $Action = 'Inspect',
    [string] $SolutionRelativePath = 'twincat\MotionSafetyBenchRuntime.sln',
    [string] $PlcContainerPath = 'TIPC^MotionSafetyBenchPLC',
    [string] $PlcIecProjectPath = 'TIPC^MotionSafetyBenchPLC^MotionSafetyBenchPLC Project',
    [string] $Configuration = 'Release',
    [string] $Platform = 'TwinCAT RT (x64)',
    [switch] $SkipBuild
)

$ErrorActionPreference = 'Stop'

if ([Environment]::Is64BitProcess) {
    $powerShell32 = Join-Path $env:WINDIR 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $powerShell32)) {
        throw "32-bit Windows PowerShell is required for TcXaeShell COM automation: $powerShell32"
    }

    $arguments32 = @(
        '-NoProfile',
        '-STA',
        '-ExecutionPolicy', 'Bypass',
        '-File', $PSCommandPath,
        '-RepositoryRoot', $RepositoryRoot,
        '-Action', $Action,
        '-SolutionRelativePath', $SolutionRelativePath,
        '-PlcContainerPath', $PlcContainerPath,
        '-PlcIecProjectPath', $PlcIecProjectPath,
        '-Configuration', $Configuration,
        '-Platform', $Platform
    )
    if ($SkipBuild) {
        $arguments32 += '-SkipBuild'
    }

    & $powerShell32 @arguments32
    exit $LASTEXITCODE
}

$openXae = @(Get-Process -Name 'TcXaeShell' -ErrorAction SilentlyContinue)
if ($openXae.Count -gt 0) {
    $processIds = ($openXae.Id | Sort-Object) -join ', '
    throw "Close all interactive TwinCAT XAE Shell windows before automated $Action (running process IDs: $processIds)."
}

$solutionPath = Join-Path $RepositoryRoot $SolutionRelativePath
$logPath = Join-Path $RepositoryRoot 'simulation\twincat_runtime_deploy.txt'

if (-not (Test-Path -LiteralPath $solutionPath)) {
    throw "TwinCAT runtime solution not found: $solutionPath"
}

$messageFilterSource = @'
using System;
using System.Runtime.InteropServices;

[ComImport]
[Guid("00000016-0000-0000-C000-000000000046")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IOleMessageFilter
{
    [PreserveSig]
    int HandleInComingCall(int callType, IntPtr taskCaller, int tickCount, IntPtr interfaceInfo);

    [PreserveSig]
    int RetryRejectedCall(IntPtr taskCallee, int tickCount, int rejectType);

    [PreserveSig]
    int MessagePending(IntPtr taskCallee, int tickCount, int pendingType);
}

public sealed class OleMessageFilter : IOleMessageFilter
{
    [DllImport("ole32.dll")]
    private static extern int CoRegisterMessageFilter(
        IOleMessageFilter newFilter,
        out IOleMessageFilter oldFilter
    );

    public static void Register()
    {
        IOleMessageFilter oldFilter;
        CoRegisterMessageFilter(new OleMessageFilter(), out oldFilter);
    }

    public static void Revoke()
    {
        IOleMessageFilter oldFilter;
        CoRegisterMessageFilter(null, out oldFilter);
    }

    int IOleMessageFilter.HandleInComingCall(
        int callType,
        IntPtr taskCaller,
        int tickCount,
        IntPtr interfaceInfo
    )
    {
        return 0;
    }

    int IOleMessageFilter.RetryRejectedCall(
        IntPtr taskCallee,
        int tickCount,
        int rejectType
    )
    {
        return rejectType == 2 ? 250 : -1;
    }

    int IOleMessageFilter.MessagePending(
        IntPtr taskCallee,
        int tickCount,
        int pendingType
    )
    {
        return 2;
    }
}
'@

Add-Type -TypeDefinition $messageFilterSource -Language CSharp
$sysManagerInterop = Join-Path $env:WINDIR `
    'assembly\GAC_MSIL\TCatSysManagerLib\3.3.0.0__180016cd49e5e8c3\TCatSysManagerLib.dll'
if (-not (Test-Path -LiteralPath $sysManagerInterop)) {
    throw "TwinCAT Automation Interface interop assembly not found: $sysManagerInterop"
}
Add-Type -Path $sysManagerInterop
[OleMessageFilter]::Register()

function Invoke-ComWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Operation,
        [int] $Attempts = 60,
        [int] $DelayMilliseconds = 500
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            return & $Operation
        }
        catch [System.Runtime.InteropServices.COMException] {
            if (
                $_.Exception.HResult -ne -2147418111 -and
                $_.Exception.HResult -ne -2147417846
            ) {
                throw
            }
            if ($attempt -eq $Attempts) {
                throw
            }
            Start-Sleep -Milliseconds $DelayMilliseconds
        }
    }
}

function Show-TwinCATTree {
    param(
        [Parameter(Mandatory = $true)]
        $Item,
        [int] $Depth = 0,
        [int] $MaximumDepth = 3
    )

    $indent = '  ' * $Depth
    Write-Output ("{0}{1} | {2} | type {3}/{4}" -f
        $indent,
        $Item.Name,
        $Item.PathName,
        $Item.ItemType,
        $Item.ItemSubType
    )

    if ($Depth -ge $MaximumDepth) {
        return
    }

    for ($index = 1; $index -le $Item.ChildCount; $index++) {
        Show-TwinCATTree -Item $Item.Child($index) -Depth ($Depth + 1) `
            -MaximumDepth $MaximumDepth
    }
}

function Set-SolutionBuildConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        $Dte,
        [Parameter(Mandatory = $true)]
        [string] $Configuration,
        [Parameter(Mandatory = $true)]
        [string] $Platform
    )

    $build = Invoke-ComWithRetry { $Dte.Solution.SolutionBuild }
    $solutionConfigurations = Invoke-ComWithRetry {
        $build.SolutionConfigurations
    }
    $configurationCount = Invoke-ComWithRetry {
        $solutionConfigurations.Count
    }

    $availableConfigurations = New-Object System.Collections.Generic.List[string]
    for ($index = 1; $index -le $configurationCount; $index++) {
        $solutionConfiguration = Invoke-ComWithRetry {
            $solutionConfigurations.Item($index)
        }
        $name = Invoke-ComWithRetry { $solutionConfiguration.Name }
        $platformName = Invoke-ComWithRetry {
            $solutionConfiguration.PlatformName
        }
        $availableConfigurations.Add("$name|$platformName")

        if (($name -eq $Configuration) -and ($platformName -eq $Platform)) {
            Invoke-ComWithRetry { $solutionConfiguration.Activate() }
            Write-Output "Active build configuration: $Configuration|$Platform"
            return
        }
    }

    throw "Solution configuration '$Configuration|$Platform' was not found. " +
        "Available configurations: $($availableConfigurations -join ', ')"
}

function Assert-TmcTargetPlatform {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepositoryRoot,
        [Parameter(Mandatory = $true)]
        [string] $ExpectedPlatform
    )

    $tmcPath = Join-Path $RepositoryRoot `
        'twincat\RuntimeSimulation\MotionSafetyBenchPLC.tmc'
    if (-not (Test-Path -LiteralPath $tmcPath)) {
        throw "Generated TMC file was not found: $tmcPath"
    }

    $tmcText = Get-Content -LiteralPath $tmcPath -Raw
    $expectedMarker = 'TargetPlatform="' + $ExpectedPlatform + '"'
    if ($tmcText -notlike "*$expectedMarker*") {
        $actualTarget = if ($tmcText -match 'TargetPlatform="([^"]+)"') {
            $Matches[1]
        }
        else {
            'not present'
        }

        throw "Generated PLC TMC target platform is '$actualTarget', " +
            "expected '$ExpectedPlatform'. Select the correct TwinCAT " +
            "runtime platform before deployment."
    }

    Write-Output "Verified generated TMC target platform: $ExpectedPlatform"
}

function Set-RuntimeSystemSymbolicMappingDisabled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepositoryRoot
    )

    $runtimeSystemPath = Join-Path $RepositoryRoot `
        'twincat\RuntimeSystem\MotionSafetyBench.tsproj'
    if (-not (Test-Path -LiteralPath $runtimeSystemPath)) {
        throw "TwinCAT runtime system project was not found: $runtimeSystemPath"
    }

    $runtimeSystemText = Get-Content -LiteralPath $runtimeSystemPath -Raw
    if ($runtimeSystemText -match 'SymbolicMapping="false"') {
        Write-Output 'Runtime system symbolic mapping guard is already present.'
        return
    }

    $updatedRuntimeSystemText = [regex]::Replace(
        $runtimeSystemText,
        '(<Instance\s+Id="#x08502040"(?:(?!>).)*?)(\s+TmcPath=)',
        '$1 SymbolicMapping="false"$2',
        1
    )

    if ($updatedRuntimeSystemText -eq $runtimeSystemText) {
        throw 'Unable to insert SymbolicMapping="false" into the PLC instance.'
    }

    Set-Content -LiteralPath $runtimeSystemPath `
        -Value $updatedRuntimeSystemText `
        -Encoding UTF8
    Write-Output 'Runtime system symbolic mapping guard inserted.'
}

Start-Transcript -LiteralPath $logPath -Force
$dte = $null

try {
    $dte = New-Object -ComObject 'TcXaeShell.DTE.15.0'
    Start-Sleep -Seconds 15
    Invoke-ComWithRetry { $dte.SuppressUI = $true }
    Invoke-ComWithRetry { $dte.MainWindow.Visible = $false }
    Invoke-ComWithRetry { $dte.Solution.Open($solutionPath) }
    Start-Sleep -Seconds 5
    Set-SolutionBuildConfiguration `
        -Dte $dte `
        -Configuration $Configuration `
        -Platform $Platform

    $systemProject = Invoke-ComWithRetry { $dte.Solution.Projects.Item(1) }
    $sysManager = Invoke-ComWithRetry { $systemProject.Object }
    $targetNetId = Invoke-ComWithRetry { $sysManager.GetTargetNetId() }
    Write-Output "Solution: $($dte.Solution.FullName)"
    Write-Output "System project: $($systemProject.FullName)"
    Write-Output "Target Net ID: $targetNetId"
    Write-Output "TwinCAT started: $($sysManager.IsTwinCATStarted())"

    $plcRoot = Invoke-ComWithRetry { $sysManager.LookupTreeItem('TIPC') }
    Show-TwinCATTree -Item $plcRoot

    # ITcSmTreeItem is enumerable. Returning it through a PowerShell function
    # expands its children into Object[], so retain the COM object directly.
    $plcContainerItem = $sysManager.LookupTreeItem($PlcContainerPath)
    $plcIecProjectItem = $sysManager.LookupTreeItem($PlcIecProjectPath)
    Write-Output "Resolved PLC container: $PlcContainerPath"
    Write-Output "Resolved IEC project: $PlcIecProjectPath"

    if ($Action -eq 'Restart') {
        Invoke-ComWithRetry { $sysManager.StartRestartTwinCAT() }
        Write-Output 'TwinCAT runtime restart requested for boot-project verification.'
        Start-Sleep -Seconds 15
    }

    if ($Action -in @('Deploy', 'Update')) {
        if (-not $SkipBuild) {
            $build = Invoke-ComWithRetry { $dte.Solution.SolutionBuild }
            Invoke-ComWithRetry { $build.Build($true) }
            if ($build.LastBuildInfo -ne 0) {
                throw "TwinCAT runtime build failed with $($build.LastBuildInfo) project error(s)."
            }
            Write-Output 'Runtime build completed with zero project errors.'
            Assert-TmcTargetPlatform `
                -RepositoryRoot $RepositoryRoot `
                -ExpectedPlatform $Platform
        }
        else {
            Write-Output 'Runtime build skipped by explicit request.'
        }

        if ($Action -eq 'Deploy') {
            Invoke-ComWithRetry { $sysManager.ActivateConfiguration() }
            Write-Output 'TwinCAT configuration activated.'
            Invoke-ComWithRetry { $sysManager.StartRestartTwinCAT() }
            Write-Output 'TwinCAT runtime restart requested.'
            Start-Sleep -Seconds 15
        }

        # PowerShell's COM wrapper exposes the IEC-project dispatch methods,
        # while an explicit PIA cast is rejected on this XAE build.
        $loginFlags = 4 -bor 256
        Invoke-ComWithRetry { $plcIecProjectItem.Login($loginFlags) }
        Write-Output 'PLC login and forced download completed.'
        Invoke-ComWithRetry { $plcIecProjectItem.Start() }
        Write-Output 'PLC application start requested.'

        Invoke-ComWithRetry { $plcContainerItem.BootProjectAutostart = $true }
        Invoke-ComWithRetry { $plcContainerItem.GenerateBootProject($true) }
        Write-Output 'PLC boot project generated and marked for autostart.'
    }
}
finally {
    if ($null -ne $dte) {
        try {
            Invoke-ComWithRetry { $dte.Quit() }
        }
        catch {
            Write-Warning "Unable to close TwinCAT XAE cleanly: $($_.Exception.Message)"
        }
    }
    Set-RuntimeSystemSymbolicMappingDisabled -RepositoryRoot $RepositoryRoot
    [OleMessageFilter]::Revoke()
    Stop-Transcript
}

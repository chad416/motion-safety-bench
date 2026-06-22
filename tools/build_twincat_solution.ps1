param(
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string] $SolutionRelativePath = 'twincat\MotionSafetyBench.sln'
)

$ErrorActionPreference = 'Stop'

if ([Environment]::Is64BitProcess) {
    $powerShell32 = Join-Path $env:WINDIR 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe'
    if (-not (Test-Path -LiteralPath $powerShell32)) {
        throw "32-bit Windows PowerShell is required for TcXaeShell COM automation: $powerShell32"
    }

    & $powerShell32 -NoProfile -STA -ExecutionPolicy Bypass -File $PSCommandPath `
        -RepositoryRoot $RepositoryRoot `
        -SolutionRelativePath $SolutionRelativePath
    exit $LASTEXITCODE
}

$openXae = @(Get-Process -Name 'TcXaeShell' -ErrorAction SilentlyContinue)
if ($openXae.Count -gt 0) {
    $processIds = ($openXae.Id | Sort-Object) -join ', '
    throw "Close all interactive TwinCAT XAE Shell windows before automated build (running process IDs: $processIds)."
}

$solutionPath = Join-Path $RepositoryRoot $SolutionRelativePath
$logPath = Join-Path $RepositoryRoot 'simulation\twincat_dte_build.txt'

if (-not (Test-Path -LiteralPath $solutionPath)) {
    throw "TwinCAT solution not found: $solutionPath"
}

Start-Transcript -LiteralPath $logPath -Force
$dte = $null

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
[OleMessageFilter]::Register()

function Invoke-ComWithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Action,
        [int] $Attempts = 40,
        [int] $DelayMilliseconds = 500
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            return & $Action
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

try {
    $dte = New-Object -ComObject 'TcXaeShell.DTE.15.0'
    Start-Sleep -Seconds 15
    Invoke-ComWithRetry { $dte.SuppressUI = $true }
    Invoke-ComWithRetry { $dte.MainWindow.Visible = $false }

    Invoke-ComWithRetry { $dte.Solution.Open($solutionPath) }
    Start-Sleep -Seconds 5

    $solutionFullName = Invoke-ComWithRetry { $dte.Solution.FullName }
    $projectCount = Invoke-ComWithRetry { $dte.Solution.Projects.Count }
    Write-Output "Solution: $solutionFullName"
    Write-Output "Projects: $projectCount"
    for ($index = 1; $index -le $projectCount; $index++) {
        $project = Invoke-ComWithRetry { $dte.Solution.Projects.Item($index) }
        Write-Output "Project[$index]: $($project.Name) | $($project.FullName)"
    }

    $build = Invoke-ComWithRetry { $dte.Solution.SolutionBuild }
    Invoke-ComWithRetry { $build.Build($true) }
    Write-Output "LastBuildInfo: $($build.LastBuildInfo)"

    foreach ($pane in $dte.ToolWindows.OutputWindow.OutputWindowPanes) {
        if ($pane.Name -match 'Build|TwinCAT') {
            try {
                $selection = $pane.TextDocument.Selection
                $selection.SelectAll()
                Write-Output "=== Output: $($pane.Name) ==="
                Write-Output $selection.Text
            }
            catch {
                Write-Warning "Unable to read output pane '$($pane.Name)': $($_.Exception.Message)"
            }
        }
    }

    if ($build.LastBuildInfo -ne 0) {
        throw "TwinCAT build failed with $($build.LastBuildInfo) project error(s)."
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
    [OleMessageFilter]::Revoke()
    Stop-Transcript
}

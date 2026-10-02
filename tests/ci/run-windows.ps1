<#
.SYNOPSIS
Launch the existing Windows installation check as a temporary standard user.
The workflow removes the scheduled task and account in its always-run cleanup step.
#>
param(
    [string]$Mode,
    [string]$Lite,
    [string]$Gui,
    [string]$Source,
    [string]$LogDirectory,
    [string]$TaskName
)

$ErrorActionPreference = 'Stop'
$user = 'dotfiles-ci'
$passwordText = 'Df!' + [guid]::NewGuid().ToString('N')
$password = ConvertTo-SecureString $passwordText -AsPlainText -Force
New-LocalUser -Name $user -Password $password -PasswordNeverExpires | Out-Null

$logDir = $LogDirectory
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
icacls $Source /grant "${env:COMPUTERNAME}\${user}:(OI)(CI)RX" /T | Out-Null
icacls $logDir /grant "${env:COMPUTERNAME}\${user}:(OI)(CI)M" /T | Out-Null

$caseScript = Join-Path $logDir 'run-case.ps1'
# Copy the checked-in child script to the same accessible location as before.
Copy-Item (Join-Path $PSScriptRoot 'run-install-windows.ps1') $caseScript

$log = Join-Path $logDir "windows-$Mode.log"
$arguments = @(
    '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
    '-File', "`"$caseScript`"", '-Mode', $Mode, '-Lite', $Lite,
    '-Gui', $Gui, '-Source', "`"$Source`"", '-Log', "`"$log`""
) -join ' '
# Task Scheduler supplies a real standard-user logon and user profile.
# RunLevel Limited preserves the production non-admin safeguard.
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
Register-ScheduledTask -TaskName $taskName -Action $action `
    -User "$env:COMPUTERNAME\$user" -Password $passwordText -RunLevel Limited -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
$deadline = (Get-Date).AddMinutes(45)
do {
    Start-Sleep -Seconds 5
    $task = Get-ScheduledTask -TaskName $taskName
    if ((Get-Date) -gt $deadline) {
        Stop-ScheduledTask -TaskName $taskName
        throw 'Standard-user installation exceeded 45 minutes'
    }
} while ($task.State -eq 'Running')
$result = (Get-ScheduledTaskInfo -TaskName $taskName).LastTaskResult
if ($result -ne 0) {
    if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log }
    throw "Standard-user task failed with exit code $result"
}

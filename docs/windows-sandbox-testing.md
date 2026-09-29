## Test Windows locally with Windows Sandbox
 

Windows Sandbox provides a disposable environment for testing a published branch. Start with lite for the quickest check. Use a fresh Sandbox for each mode so packages from earlier tests cannot affect the result.

### Start the sandbox

Use an x64 Windows 11 host with virtualization enabled. Enable **Windows Sandbox** in **Turn Windows features on or off**, then restart if requested. See Microsoft's [installation requirements](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-install).

Save this as `dotfiles.wsb` on the host and double-click it:

```xml
<Configuration>
  <MemoryInMB>8192</MemoryInMB>
  <vGPU>Enable</vGPU>
  <Networking>Enable</Networking>
  <LogonCommand>
    <Command>powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -NoExit</Command>
  </LogonCommand>
</Configuration>
```

See Microsoft's [Sandbox configuration reference](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file) for these settings.

### Open PowerShell as a standard user

Inside the sandbox, create a standard user for the installer. Set a temporary administrator password for PowerShell MSI elevation and record the account printed by `whoami`.

```powershell
whoami
$adminPassword = Read-Host 'Temporary sandbox administrator password' -AsSecureString
Set-LocalUser -Name $env:USERNAME -Password $adminPassword
$testPassword = Read-Host 'Temporary dotfiles-test password' -AsSecureString
New-LocalUser -Name 'dotfiles-test' -Password $testPassword | Out-Null
$usersGroup = Get-LocalGroup -SID 'S-1-5-32-545'
Add-LocalGroupMember -Group $usersGroup -Member 'dotfiles-test'
runas.exe /profile /user:"$env:COMPUTERNAME\dotfiles-test" "powershell.exe -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass"
```

Enter the test user's password at the `runas` prompt. Continue in the new window. Confirm that `whoami` identifies `dotfiles-test` and `$HOME` points to that user's profile. Keep the original administrator window open.

### Install from GitHub

In the test user's window, start logging. Use a test email and choose lite, full CLI, or full GUI when prompted. When the PowerShell MSI helper requests elevation, enter the sandbox administrator credentials. Keep Chezmoi running as `dotfiles-test`.

```powershell
$ErrorActionPreference = 'Stop'
Set-Location $HOME
Start-Transcript -Path "$HOME\dotfiles-test.log"
```

Run the Windows README bootstrap command:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '~/bin' -- init -S ~/dotfiles --apply hmvege"
if ($LASTEXITCODE -ne 0) { throw 'First apply failed' }
```

To test a published branch, use this instead of the preceding command:

```powershell
$branch = 'your-published-branch'
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '~/bin' -- init -S ~/dotfiles --branch '$branch' --apply hmvege"
if ($LASTEXITCODE -ne 0) { throw 'First apply failed' }
```

After the chosen bootstrap command succeeds, stop logging:

```powershell
Stop-Transcript
```

### Verify and repeat

From the test user's window, start PowerShell 7 explicitly:

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe" -NoLogo -NoProfile
```

In the new shell, set `$mode` to match your installation: `lite`, `full-cli`, or `full-gui`. Run the verifier and repeat apply:

```powershell
$ErrorActionPreference = 'Stop'
$mode = 'lite'
$source = Join-Path $HOME 'dotfiles'
$chezmoi = Join-Path $HOME 'bin\chezmoi.exe'
Start-Transcript -Path "$HOME\dotfiles-test.log" -Append
git -C $source rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot record tested commit' }
& "$source\tests\verify-windows.ps1" -Mode $mode

& $chezmoi -S $source state delete-bucket --bucket=scriptState
if ($LASTEXITCODE -ne 0) { throw 'Run-once state reset failed' }
& $chezmoi -S $source apply
if ($LASTEXITCODE -ne 0) { throw 'Repeat apply failed' }
& "$source\tests\verify-windows.ps1" -Mode $mode
& $chezmoi -S $source verify -x scripts
if ($LASTEXITCODE -ne 0) { throw 'Configuration verification failed' }
Stop-Transcript
```

Stop at any error. Run all verification steps because apply can skip optional installation failures.

Open PowerShell 7 normally as the test user and check profile startup, fzf history, and zoxide. For full GUI, also launch VSCode and Sublime Merge and inspect font rendering. Record the tested commit, Windows version, mode, and results.

Copy `dotfiles-test.log` from the test user's home to the host before closing Sandbox.

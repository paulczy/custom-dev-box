param([String]$azureFilesKey, [string]$account="squadstorage", [string]$share="software")

pwsh -MTA -noni -nop -ex Unrestricted -File c:\scripts\Install-SystemSoftware.ps1

$v = Mount-VHD c:\devdrive.vhdx -Passthru | Get-Disk | Get-Partition | Get-Volume
Write-Output $v
if ($v.DriveLetter -ne 'D') {
    & $PSScriptRoot\Run-WithStatus.ps1 "Changing DevDrive drive letter" { & $PSScriptRoot\Update-DriveLetter.ps1 "$($v.DriveLetter):" 'D:' }
}

$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -MultipleInstances IgnoreNew -RunOnlyIfNetworkAvailable
& $PSScriptRoot\Run-WithStatus.ps1 "Adding One Time Setup scheduled task" { 
    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "$PSScriptRoot\Apply-OneTimeUserSetup.ps1 -taskName 'One Time Setup'"
    $Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Highest
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings
    Register-ScheduledTask -TaskName "One Time Setup" -InputObject $Task
}

& $PSScriptRoot\Run-WithStatus.ps1 "Adding S: mount scheduled task" { 
    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "$PSScriptRoot\Mount-AzureFiles.ps1 -key $azureFilesKey -account $account -share $share"
    $Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings
    Register-ScheduledTask -TaskName "Mount Squad Software storage" -InputObject $Task
}

& $PSScriptRoot\Run-WithStatus.ps1 "Cleaning up desktop" { rm -Force C:\Users\Public\Desktop\*.lnk }
# & $PSScriptRoot\Run-WithStatus.ps1 "Removing DVD drive from the system" { Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\cdrom -Name Start -Value 4 -Type DWord }
& $PSScriptRoot\Run-WithStatus.ps1 "Disabling Reserved Storage" { DISM.exe /Online /Set-ReservedStorageState /State:Disabled }

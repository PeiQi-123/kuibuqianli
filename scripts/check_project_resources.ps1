Write-Host "==== Top 15 processes by memory (system-wide) ===="
Get-Process |
  Sort-Object -Descending WS |
  Select-Object -First 15 `
    @{Name='Name';Expression={$_.ProcessName}},
    @{Name='Id';Expression={$_.Id}},
    @{Name='CPU(s)';Expression={[math]::Round(($_.CPU),1)}},
    @{Name='Memory(MB)';Expression={[math]::Round(($_.WS/1MB),1)}} |
  Format-Table -AutoSize

# Detect project root (assuming script is in repo\scripts\)
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = (Resolve-Path (Join-Path $scriptDir ".."))

Write-Host ""
Write-Host "Project root detected: $projectDir" 
Write-Host "==== Processes started from this project (by memory) ===="

# Find processes whose command line contains the project path
$projProcs = Get-CimInstance Win32_Process |
  Where-Object {
    $_.CommandLine -and $_.CommandLine -like "*$projectDir*"
  }

if (-not $projProcs) {
  Write-Host "No processes found with command line containing project path."
} else {
  $procIds = $projProcs.ProcessId
  Get-Process -Id $procIds -ErrorAction SilentlyContinue |
    Sort-Object -Descending WS |
    Select-Object `
      @{Name='Name';Expression={$_.ProcessName}},
      @{Name='Id';Expression={$_.Id}},
      @{Name='CPU(s)';Expression={[math]::Round(($_.CPU),1)}},
      @{Name='Memory(MB)';Expression={[math]::Round(($_.WS/1MB),1)}} |
    Format-Table -AutoSize

  Write-Host ""
  Write-Host "NOTE: These are likely your backend (java/mvn), frontend (flutter/dart), AI service (python), etc."
}

Write-Host ""
Write-Host "Done. Check the tables above to see who is using memory."

# Keep window open when double-clicked
Write-Host ""
Read-Host "Press Enter to exit..." | Out-Null

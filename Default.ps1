Set-Location $PSScriptRoot
$dataFile = $MyInvocation.MyCommand -replace ".ps1", ".txt"
$result = 0

$lines = Get-Content -Path "./$dataFile"
$lines | ForEach-Object {
	
}

Write-Host "Result: $result"
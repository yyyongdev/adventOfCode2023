Set-Location $PSScriptRoot
$dataFile = $MyInvocation.MyCommand -replace ".ps1", ".input"
$result = 0
$mapData = @{}

Function ConvertMappingValue($ConvertInfo, [long]$Number) {
    foreach ($info in $ConvertInfo) {
        if ($Number -ge $info.Start -and $Number -le $info.End) {
            return $Number + $info.Gap
        }
    }
    return $Number
}

$lines = Get-Content -Path "./$dataFile"
$seedLine, $lines = $lines

$lines | ForEach-Object {
    if ($_ -eq "") {
        return
    }
    if ($_ -match '(.*)-(.*)-(.*) map:') {
        $from = $matches[1]
        $to = $matches[3]
        $mapData["${from}:${to}"] = @()
    }
    else {
        $numbers = $_.Split()
        $start = [long]$numbers[1]
        $len = [long]$numbers[2]
        $end = $start + $len - 1
        $newStart = [long]$numbers[0]
        $gap = $newStart - $start

        $mapData["${from}:${to}"] += @{
            'Start' = $start
            'End'   = $end
            'Gap'   = $gap
        }
    }
}

if ($seedLine -match 'seeds: (.*)') {
    $seeds = $matches[1].Split()
    $seeds | ForEach-Object -Begin { $lowest = [long]::MaxValue } -Process {
        $seed = [long]$_
        $soil = ConvertMappingValue -ConvertInfo $mapData['seed:soil'] -Number $seed
        $fertilizer = ConvertMappingValue -ConvertInfo $mapData['soil:fertilizer'] -Number $soil
        $water = ConvertMappingValue -ConvertInfo $mapData['fertilizer:water'] -Number $fertilizer
        $light = ConvertMappingValue -ConvertInfo $mapData['water:light'] -Number $water
        $temperature = ConvertMappingValue -ConvertInfo $mapData['light:temperature'] -Number $light
        $humidity = ConvertMappingValue -ConvertInfo $mapData['temperature:humidity'] -Number $temperature
        $location = ConvertMappingValue -ConvertInfo $mapData['humidity:location'] -Number $humidity
        
        $lowest = [Math]::Min($lowest, $location)
    }
    $result = $lowest
}

Write-Host "Result: $result"

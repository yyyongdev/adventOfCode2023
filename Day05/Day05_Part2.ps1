Set-Location $PSScriptRoot
$dataFile = $MyInvocation.MyCommand -replace ".ps1", ".input"
$result = 0
$mapData = @{}

Function ConvertMappingRange($ConvertInfo, $Ranges) {
    $retArray = @()
    foreach ($range in $Ranges) {
        $tempArray = @()
        foreach ($info in $ConvertInfo) {
            #     [ Info ]
            # [    Range    ]
            if ($info.Start -ge $range.Start -and $info.End -le $range.End) {
                $tempArray += @{ 'Start' = $info.Start + $info.Gap; 'End' = $info.End + $info.Gap }
                $tempArray += @{ 'Start' = $range.Start; 'End' = $info.Start - 1 }
                $tempArray += @{ 'Start' = $info.End + 1; 'End' = $range.End }
            }
            # [     Info     ]
            #     [ Range ]
            elseif ($info.Start -le $range.Start -and $info.End -ge $range.End) {
                $tempArray += @{ 'Start' = $range.Start + $info.Gap; 'End' = $range.End + $info.Gap }
            }
            # [  Info  ]      |      [  Info  ] 
            #       [ Range ] | [ Range ]
            elseif (($info.End -ge $range.Start -and $info.End -le $range.End) -or
                    ($info.Start -le $range.End -and $info.Start -ge $range.Start)) {
                $tempArray += @{ 'Start'= [Math]::Max($info.Start, $range.Start) + $info.Gap; 'End'= [Math]::Min($info.End, $range.End) + $info.Gap }
                $tempArray += @{ 'Start' = $info.Start; 'End'= $range.Start - 1 }
                $tempArray += @{ 'Start' = $info.End + 1; 'End'= $range.End }
            }
        }
        if ($tempArray.Length -eq 0) {
            $tempArray += $range
        }
        $retArray += $tempArray
    }
    return $retArray
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
    $seeds = @()
    $seedInfo = $matches[1].Split();
    for ($i = 0; $i -lt $seedInfo.Length; $i += 2) {
        $seeds += @{
            'Start' = [long]$seedInfo[$i]
            'End' = [long]$seedInfo[$i] + [long]$seedInfo[$i + 1] - 1
        }
    }
    $soils = ConvertMappingRange -ConvertInfo $mapData['seed:soil'] -Range $seeds
    $fertilizers = ConvertMappingRange -ConvertInfo $mapData['soil:fertilizer'] -Range $soils
    $waters = ConvertMappingRange -ConvertInfo $mapData['fertilizer:water'] -Range $fertilizers
    $lights = ConvertMappingRange -ConvertInfo $mapData['water:light'] -Range $waters
    $temperatures = ConvertMappingRange -ConvertInfo $mapData['light:temperature'] -Range $lights
    $humidities = ConvertMappingRange -ConvertInfo $mapData['temperature:humidity'] -Range $temperatures
    $locations = ConvertMappingRange -ConvertInfo $mapData['humidity:location'] -Range $humidities
    
    $lowest = [long]::MaxValue
    $locations | ForEach-Object {
        $lowest = [Math]::Min($lowest, $_.Start)
    }
    $result = $lowest
}

Write-Host "Result: $result"

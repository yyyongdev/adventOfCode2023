Set-Location $PSScriptRoot
$dataFile = $MyInvocation.MyCommand -replace ".ps1", ".input"
$result = 0

$hands = @()
$lines = Get-Content -Path "./$dataFile"
$lines | ForEach-Object {
	$card, $money = $_.Split()
	$dupicateCard = $card.ToCharArray() | Group-Object | Sort-Object Count -Descending | Select-Object -First 1
	
	$hands += @{
		'Card'           = $card
		'Money'          = $money
		'DuplicateCount' = $dupicateCard.Count
	}
}

$orderTable = @{
	'A' = 0; 'K' = 1; 'Q' = 2; 'J' = 3; 'T' = 4
	'9' = 5; '8' = 6; '7' = 7; '6' = 8; '5' = 9; '4' = 10; '3' = 11; '2' = 12
}

$orderedHands = $hands | Sort-Object -Property @{ Expression = { $_.DuplicateCount }; Descending = $false },
												@{ Expression = { $orderTable[$_.Card[0].ToString()] }; Descending = $true },
												@{ Expression = { $orderTable[$_.Card[1].ToString()] }; Descending = $true },
												@{ Expression = { $orderTable[$_.Card[2].ToString()] }; Descending = $true },
												@{ Expression = { $orderTable[$_.Card[3].ToString()] }; Descending = $true },
												@{ Expression = { $orderTable[$_.Card[4].ToString()] }; Descending = $true }

$orderedHands | ForEach-Object -Begin { $index = 1 } -Process { 
	$result += $index * $_.Money
	$index++
}
Write-Host "Result: $result"
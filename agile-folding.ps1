$BASE_URL = "https://api.octopus.energy"
$PRODUCT_CODE = "AGILE-FLEX-22-11-25"
$TARIFF_CODE = "E-1R-$PRODUCT_CODE-B"
$TARIFF_URL = "$BASE_URL/v1/products/$PRODUCT_CODE/electricity-tariffs/$TARIFF_CODE/standard-unit-rates/"

$response = Invoke-RestMethod -Uri $TARIFF_URL -Method Get

$roundedDateTime = Get-Date $currentDateTime -Format 'yyyy-MM-ddTHH:mm:ssZ' | ForEach-Object {
    [datetime]::ParseExact($_, 'yyyy-MM-ddTHH:mm:ssZ', $null)
}
$roundedDateTime = $roundedDateTime.AddMinutes(-($roundedDateTime.Minute % 30))
Write-Host "Rounded Current Time: $($roundedDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

$currentRate = $response.results | Where-Object {
    $roundedDateTime -ge $_.valid_from -and $roundedDateTime -lt $_.valid_to
}

if ($currentRate) {
    Write-Host "Rate for Rounded Time: $($currentRate.value_inc_vat)"

    if ($currentRate.value_inc_vat -lt 0) {
        Write-Host "Starting Folding@home..."
        $shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Folding@home\Folding@home.lnk"
        Invoke-Item $shortcutPath
    } elseif (Test-Path "C:\Program Files (x86)\FAHClient\FAHClient.exe") {
        $fahProcess = Get-Process -Name FAHClient -ErrorAction SilentlyContinue
        if ($fahProcess) {
            Write-Host "Folding@home is running. Stopping..."
            $clientPath = "C:\Program Files (x86)\FAHClient\FAHClient.exe"
            $stopCommand = "--send-command 'shutdown'"
            Start-Process -FilePath $clientPath -ArgumentList $stopCommand -NoNewWindow -Wait
        } else {
            Write-Host "Folding@home process not found. It may already be stopped."
        }
    } else {
        Write-Host "Folding@home is not installed."
    }
} else {
    Write-Host "No rate found for the rounded time."
}

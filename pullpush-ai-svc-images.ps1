. .\PullPush-AISvcImage.ps1

$harborRegistry = 'localhost:8090'
# docker login $harborRegistry

# AI Services, except text analytics sentiment, speech to text
$content = Get-Content -Path .\ai-services.jsonc -Raw
$aiSvcImages = $content | ConvertFrom-Json -Depth 3
# $aiSvcImages = @($aiSvcImages[0]) # for testing
$aiSvcImages = $aiSvcImages | Where-Object { $_.image -like "*translator*" }

# text analytics sentiment
$aiSvcImages = @()
$content = Get-Content -Path .\speech-to-text-tags.csv -Raw
$langs = $content | ConvertFrom-Csv
$langs | ForEach-Object {
    $lang = $_.lang.ToLower()
    $aiSvcImages += [PSCustomObject]@{
        image = "mcr.microsoft.com/azure-cognitive-services/textanalytics/sentiment"
        tags  = @($lang)
    }
}
$aiSvcImages = $aiSvcImages | Where-Object { $_.tags -contains "3.0-en" }


# speech to text
$aiSvcImages = @()
$content = Get-Content -Path .\speech-to-text-tags.csv -Raw
$langs = $content | ConvertFrom-Csv
$langs | ForEach-Object {
    $lang = $_.lang.ToLower()
    $aiSvcImages += [PSCustomObject]@{
        image = "mcr.microsoft.com/azure-cognitive-services/speechservices/speech-to-text"
        tags  = @($lang)
    }
}
$aiSvcImages = $aiSvcImages | Where-Object { $_.tags -contains "5.0.3-preview-amd64-en-us" }

# neural text to speech
$aiSvcImages = @()
$content = Get-Content -Path .\neural-text-to-speech-tags.csv -Raw
$langs = $content | ConvertFrom-Csv
$langs | ForEach-Object {
    $tag = $_.tag.ToLower()
    $aiSvcImages += [PSCustomObject]@{
        image = "mcr.microsoft.com/azure-cognitive-services/speechservices/neural-text-to-speech"
        tags  = @($tag)
    }
}
$aiSvcImages = $aiSvcImages | Where-Object { $_.tags -contains "1.16.0-amd64-en-us-ariarus" }

# Main execution
Write-Host "Starting Azure AI Services container pull process..." -ForegroundColor Magenta
Write-Host "Current date: $(Get-Date)" -ForegroundColor Magenta
Write-Host ""

# Create a summary array to track results
$pullResults = @()

foreach ($imageInfo in $aiSvcImages) {
    $startTime = Get-Date
    
    try {
        PullPush-AISvcImage -ImageName $imageInfo.image -Tags $imageInfo.tags -TargetRegistry $harborRegistry
        
        $pullResults += [PSCustomObject]@{
            Image = $imageInfo.image
            Status = "Success"
            Duration = ((Get-Date) - $startTime).TotalSeconds
            Tags = $imageInfo.tags -join ", "
        }
    }
    catch {
        $pullResults += [PSCustomObject]@{
            Image = $imageInfo.image
            Status = "Failed"
            Duration = ((Get-Date) - $startTime).TotalSeconds
            Error = $_.Exception.Message
            Tags = $imageInfo.tags -join ", "
        }
    }
}

# Display summary
Write-Host "=" * 100 -ForegroundColor Magenta
Write-Host "PULL SUMMARY" -ForegroundColor Magenta
Write-Host "=" * 100 -ForegroundColor Magenta

$pullResults | Format-Table -AutoSize

Write-Host ""
Write-Host "Total images processed: $($pullResults.Count)" -ForegroundColor Cyan
Write-Host "Successful pulls: $($pullResults | Where-Object {$_.Status -eq 'Success'} | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
Write-Host "Failed pulls: $($pullResults | Where-Object {$_.Status -eq 'Failed'} | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Red

# List all pulled images
Write-Host ""
Write-Host "Listing all Azure Cognitive Services images:" -ForegroundColor Cyan
docker images | Where-Object { $_ -match "azure-cognitive-services" }

Write-Host ""
Write-Host "Pull process completed!" -ForegroundColor Magenta
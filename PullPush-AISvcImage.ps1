# Function to pull all tags for a given image
function PullPush-AISvcImage {
    param(
        [string]$ImageName,
        [array]$Tags,
        [string]$TargetRegistry = "localhost:8090" # assumed logged in
    )
    
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "Processing image: $ImageName" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    $Tags | ForEach-Object {
        $tag = $_
        $fullImageName = "${ImageName}:${tag}"
        Write-Host "Pulling: $fullImageName" -ForegroundColor Yellow
        
        try {
            docker pull $fullImageName
            if(![string]::IsNullOrEmpty($TargetRegistry)) {
                docker tag $fullImageName $TargetRegistry/library/$fullImageName
                docker push $TargetRegistry/library/$fullImageName
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Successfully pulled: $fullImageName" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to pull: $fullImageName" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "✗ Error pulling $fullImageName : $_" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}
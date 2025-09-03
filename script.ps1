az login --tenant $env:MNGENV_TENANT_ID
az account set --subscription $env:MNGENV_SUBSCRIPTION_ID
az account show


$rgName = 'rg-omp-auea-dev-01'
$acrName = 'crompctrsaueadev01'
$apiVersion = '2025-05-01-preview'
az resource update --resource-group $rgName `
    --name $acrName `
    --resource-type "Microsoft.ContainerRegistry/registries" `
    --api-version $apiVersion `
    --set "properties.policies.exportPolicy.status=enabled" `
    --set "properties.publicNetworkAccess=enabled"

az acr login --name $acrName

$images = @(
    @{ 
        image = "mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-4.0" 
        tags = @("latest", "2024-11-30", "2024-11-30.20250828.1-26420265") 
    },
    @{
        image = "mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0"
        tags = @("latest", "2024-11-30", "2024-11-30.20250828.1-26420265")
    }
)
foreach ($image in $images) {
    Write-Host "Pulling image: $image"
    docker pull $image

    $imageName = $image -replace '[:/]', '-'
    $taggedImage = "$acrName.azurecr.io/$imageName"

    Write-Host "Tagging image as: $taggedImage"
    docker tag $image $taggedImage

    Write-Host "Pushing image to ACR: $taggedImage"
    docker push $taggedImage

    az acr import -n $acrName --source $taggedImage --image $imageName
}

# Document Intelligence
$endpointUri = $env:MNGENV_DOCINTEL_ENDPOINT_URI # 'https://di-ac-ae-001.cognitiveservices.azure.com/'
$apiKey = $env:MNGENV_DOCINTEL_API_KEY
$licenseMount = "/c/cog/licenses:/license"
$image = "mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-4.0:latest"
$subDir = "form-recognizer-layout"
# download licence
docker run --rm -it -p 5000:5000 `
    -v $licenseMount `
    $image `
    eula=accept `
    billing=$endpointUri `
    apikey=$apiKey `
    DownloadLicense=True `
    Mounts:License=$subDir

# use with the license
$memorySize = "8g"
$numberCpus = 4
$outputMount = "/c/cog/output:/output"
docker run --rm -it -p 5000:5050 --memory $memorySize --cpus $numberCpus `
    -v $licenseMount `
    -v $outputMount `
    $image `
    eula=accept `
    Mounts:License=$subDir `
    Mounts:Output=$subDir

# Translator
$endpointUri = $env:MNGENV_TRANSLATOR_ENDPOINT_URI # 'https://trls-ac-ae-001.cognitiveservices.azure.com/'
$apiKey = $env:MNGENV_TRANSLATOR_API_KEY
docker run --rm -it -p 5000:5000 --memory 12g --cpus 4 `
    -v /mnt/d/TranslatorContainer:/usr/local/models `
    -e apikey=$apiKey `
    -e eula=accept `
    -e billing=$3ndpointUri `
    -e Languages=en,fr,es,ar,ru `
    localhost:8090/library/mcr.microsoft.com/azure-cognitive-services/translator/text-translation:latest
    # mcr.microsoft.com/azure-cognitive-services/translator/text-translation:latest
# Kubernetes Deployment Script for AI Services
# This script deploys Azure Cognitive Services containers to a local Docker Desktop Kubernetes cluster

param(
    [string]$DocIntelEndpoint = $env:MNGENV_DOCINTEL_ENDPOINT_URI,
    [string]$DocIntelApiKey = $env:MNGENV_DOCINTEL_API_KEY,
    [string]$TranslatorEndpoint = $env:MNGENV_TRANSLATOR_ENDPOINT_URI,
    [string]$TranslatorApiKey = $env:MNGENV_TRANSLATOR_API_KEY,
    [switch]$Deploy,
    [switch]$Delete,
    [switch]$Status
)

function Test-RequiredTools {
    Write-Host "Checking required tools..." -ForegroundColor Yellow
    
    if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed or not in PATH"
        return $false
    }
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "docker is not installed or not in PATH"
        return $false
    }
    
    # Check if Kubernetes is running
    try {
        kubectl cluster-info | Out-Null
        Write-Host "✓ Kubernetes cluster is accessible" -ForegroundColor Green
    }
    catch {
        Write-Error "Kubernetes cluster is not accessible. Make sure Docker Desktop Kubernetes is enabled."
        return $false
    }
    
    return $true
}

function Update-Secrets {
    param(
        [string]$DocIntelEndpoint,
        [string]$DocIntelApiKey,
        [string]$TranslatorEndpoint,
        [string]$TranslatorApiKey
    )
    
    if (!$DocIntelEndpoint -or !$DocIntelApiKey -or !$TranslatorEndpoint -or !$TranslatorApiKey) {
        Write-Error "Missing required environment variables. Please set:"
        Write-Host "  MNGENV_DOCINTEL_ENDPOINT_URI" -ForegroundColor Yellow
        Write-Host "  MNGENV_DOCINTEL_API_KEY" -ForegroundColor Yellow
        Write-Host "  MNGENV_TRANSLATOR_ENDPOINT_URI" -ForegroundColor Yellow
        Write-Host "  MNGENV_TRANSLATOR_API_KEY" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "Updating secrets with base64 encoded values..." -ForegroundColor Yellow
    
    # Base64 encode the values
    $docIntelEndpointB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($DocIntelEndpoint))
    $docIntelApiKeyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($DocIntelApiKey))
    $translatorEndpointB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TranslatorEndpoint))
    $translatorApiKeyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TranslatorApiKey))
    
    # Update secrets.yaml
    $secretsContent = Get-Content "k8s\secrets.yaml" -Raw
    $secretsContent = $secretsContent -replace 'docintel-endpoint-uri: ""', "docintel-endpoint-uri: $docIntelEndpointB64"
    $secretsContent = $secretsContent -replace 'docintel-api-key: ""', "docintel-api-key: $docIntelApiKeyB64"
    $secretsContent = $secretsContent -replace 'translator-endpoint-uri: ""', "translator-endpoint-uri: $translatorEndpointB64"
    $secretsContent = $secretsContent -replace 'translator-api-key: ""', "translator-api-key: $translatorApiKeyB64"
    
    Set-Content "k8s\secrets.yaml" $secretsContent
    Write-Host "✓ Secrets updated" -ForegroundColor Green
    return $true
}

function Deploy-Services {
    Write-Host "Deploying AI Services to Kubernetes..." -ForegroundColor Yellow
    
    # Create directories on host if they don't exist
    Write-Host "Creating host directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "C:\data\cog\licenses" | Out-Null
    New-Item -ItemType Directory -Force -Path "C:\data\cog\output" | Out-Null
    
    # Deploy manifests in order
    $manifests = @(
        "k8s\namespace.yaml",
        "k8s\secrets.yaml",
        "k8s\storage.yaml",
        "k8s\document-intelligence.yaml",
        "k8s\translator.yaml"
    )
    
    foreach ($manifest in $manifests) {
        Write-Host "Applying $manifest..." -ForegroundColor Cyan
        kubectl apply -f $manifest
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply $manifest"
            return $false
        }
    }
    
    Write-Host "`n✓ All manifests applied successfully!" -ForegroundColor Green
    Write-Host "`nWaiting for deployments to be ready..." -ForegroundColor Yellow
    
    # Wait for deployments
    kubectl wait --for=condition=available --timeout=300s deployment/document-intelligence -n ai-services
    kubectl wait --for=condition=available --timeout=300s deployment/translator -n ai-services
    
    Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
    Show-Status
    return $true
}

function Remove-Services {
    Write-Host "Removing AI Services from Kubernetes..." -ForegroundColor Yellow
    
    kubectl delete namespace ai-services --ignore-not-found=true
    Write-Host "✓ AI Services removed" -ForegroundColor Green
}

function Show-Status {
    Write-Host "`n=== AI Services Status ===" -ForegroundColor Cyan
    
    Write-Host "`nNamespace:" -ForegroundColor Yellow
    kubectl get namespace ai-services 2>$null
    
    Write-Host "`nDeployments:" -ForegroundColor Yellow
    kubectl get deployments -n ai-services 2>$null
    
    Write-Host "`nServices:" -ForegroundColor Yellow
    kubectl get services -n ai-services 2>$null
    
    Write-Host "`nPods:" -ForegroundColor Yellow
    kubectl get pods -n ai-services 2>$null
    
    Write-Host "`nService Endpoints:" -ForegroundColor Yellow
    Write-Host "  Document Intelligence: http://localhost:30500" -ForegroundColor Green
    Write-Host "  Translator: http://localhost:30501" -ForegroundColor Green
}

# Main execution
if (!Test-RequiredTools) {
    exit 1
}

if ($Deploy) {
    if (Update-Secrets -DocIntelEndpoint $DocIntelEndpoint -DocIntelApiKey $DocIntelApiKey -TranslatorEndpoint $TranslatorEndpoint -TranslatorApiKey $TranslatorApiKey) {
        Deploy-Services
    }
}
elseif ($Delete) {
    Remove-Services
}
elseif ($Status) {
    Show-Status
}
else {
    Write-Host "AI Services Kubernetes Deployment Script" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\deploy-k8s.ps1 -Deploy    # Deploy services to Kubernetes"
    Write-Host "  .\deploy-k8s.ps1 -Delete    # Remove services from Kubernetes"
    Write-Host "  .\deploy-k8s.ps1 -Status    # Show deployment status"
    Write-Host "`nMake sure to set the required environment variables before deploying." -ForegroundColor Yellow
}

# Azure Cognitive Services on Kubernetes

This directory contains Kubernetes manifests to deploy Azure Cognitive Services containers to a local Docker Desktop Kubernetes cluster.

## Prerequisites

1. **Docker Desktop** with Kubernetes enabled
2. **kubectl** command-line tool
3. **Valid Azure Cognitive Services** endpoints and API keys

## Services Included

- **Document Intelligence** (Form Recognizer Layout 4.0)
- **Translator** (Text Translation)

## Quick Start

### 1. Set Environment Variables

Set the following environment variables with your Azure Cognitive Services credentials:

```powershell
$env:MNGENV_DOCINTEL_ENDPOINT_URI = "https://your-doc-intelligence-endpoint.cognitiveservices.azure.com/"
$env:MNGENV_DOCINTEL_API_KEY = "your-doc-intelligence-api-key"
$env:MNGENV_TRANSLATOR_ENDPOINT_URI = "https://your-translator-endpoint.cognitiveservices.azure.com/"
$env:MNGENV_TRANSLATOR_API_KEY = "your-translator-api-key"
```

### 2. Deploy Services

```powershell
cd k8s
.\deploy-k8s.ps1 -Deploy
```

### 3. Check Status

```powershell
.\deploy-k8s.ps1 -Status
```

### 4. Access Services

Once deployed, the services will be available at:

- **Document Intelligence**: http://localhost:30500
- **Translator**: http://localhost:30501

## Manual Deployment

If you prefer to deploy manually:

1. **Apply manifests in order:**
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f secrets.yaml  # Update with your base64 encoded credentials first
   kubectl apply -f storage.yaml
   kubectl apply -f document-intelligence.yaml
   kubectl apply -f translator.yaml
   ```

2. **Wait for deployments:**
   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/document-intelligence -n ai-services
   kubectl wait --for=condition=available --timeout=300s deployment/translator -n ai-services
   ```

## Manifest Files

- **`namespace.yaml`**: Creates the ai-services namespace
- **`secrets.yaml`**: Stores API keys and endpoints (base64 encoded)
- **`storage.yaml`**: PersistentVolumes and PersistentVolumeClaims for data persistence
- **`document-intelligence.yaml`**: Document Intelligence deployment and service
- **`translator.yaml`**: Translator deployment and service
- **`deploy-k8s.ps1`**: PowerShell deployment script

## Storage

The manifests create persistent volumes that map to local directories:

- **Licenses**: `C:\data\cog\licenses` → `/license` (in container)
- **Output**: `C:\data\cog\output` → `/output` (in container)
- **Translator Models**: `D:\TranslatorContainer` → `/usr/local/models` (in container)

## Resource Requirements

### Document Intelligence
- Memory: 8GB
- CPU: 4 cores
- Port: 30500

### Translator
- Memory: 12GB
- CPU: 4 cores
- Port: 30501

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n ai-services
kubectl describe pod <pod-name> -n ai-services
```

### View Logs
```bash
kubectl logs <pod-name> -n ai-services
```

### Check Services
```bash
kubectl get services -n ai-services
```

### Storage Issues
Make sure the host directories exist and are accessible:
- `C:\data\cog\licenses`
- `C:\data\cog\output`
- `D:\TranslatorContainer`

## Cleanup

To remove all deployed resources:

```powershell
.\deploy-k8s.ps1 -Delete
```

Or manually:
```bash
kubectl delete namespace ai-services
```

## Notes

- The containers require valid Azure Cognitive Services endpoints and API keys
- Licenses are downloaded automatically when the containers start
- The services use NodePort type for easy access from localhost
- Health checks are configured for both services
- Resource limits are set based on the original Docker commands

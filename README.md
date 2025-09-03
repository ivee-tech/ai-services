# AI Services Disconnected Containers

> **Note:**
>
> The code and instructions are located here: 
<br/>
> https://github.com/ivee-tech/ai-services
>
> The code to pull / push images can be executed in a testing environment, however the disconnected containers execution cannot be tested as it requires special licensing from Microsoft.  

This repository contains sample scripts and configuration files to deploy and use Azure Cognitive Services (AI Services) containers in disconnected mode using Harbor as a local container registry.

## Overview

The solution enables running Azure AI Services containers in air-gapped or disconnected environments by:
1. Installing and configuring Harbor as a local container registry
2. Pulling AI Services container images from Microsoft Container Registry (MCR) and pushing them to Harbor
3. Downloading necessary license files and language models
4. Running AI Services containers in disconnected mode

## Prerequisites

- Docker Desktop or Docker Engine
- PowerShell (Windows) or Bash (Linux/macOS)
- Internet connectivity (for initial setup and image downloads)
- Azure Cognitive Services subscription (for obtaining API keys and endpoints)

### Prerequisites for Private Endpoint Deployment

To deploy AI Services behind private endpoints in your nominated subscription, you'll need:

#### Azure Infrastructure Requirements

- **Virtual Network (VNet)**: A VNet with appropriate CIDR ranges (e.g., `10.3.0.0/24`)
- **Private Endpoints Subnet**: Dedicated subnet for private endpoints (e.g., `10.3.0.0/27`)
- **DNS Configuration**: Private DNS zones or custom DNS resolution for private endpoints
- **Network Security Groups (NSGs)**: Properly configured to allow traffic between subnets

#### Azure Permissions

- **Owner** or **Contributor** role on the target subscription
- **Network Contributor** role for VNet and subnet operations
- **Private DNS Zone Contributor** role (if using Azure Private DNS)
- **Key Vault Administrator** or **Key Vault Secrets Officer** (if using Key Vault for secrets)

#### Azure Services and Resources

- **Azure AI Services** (Cognitive Services) instances deployed in the subscription
- **Private DNS Zones** for service-specific endpoints:
  - `privatelink.cognitiveservices.azure.com` (for AI Services)
  - `privatelink.openai.azure.com` (for Azure OpenAI Service)
- **Azure Key Vault** (recommended for storing API keys and secrets)
- **Azure Container Registry** (if using custom container images)

#### Network Planning

Based on your VNet configuration (`10.3.0.0/24` with private endpoints subnet `10.3.0.0/27`):

- **Available address space**: 10.3.0.32 - 10.3.0.255 (224 IP addresses)
- **Recommended additional subnets**:
  - Container subnet: `/28` (11 usable IPs) - e.g., `10.3.0.32/28`
  - Application subnet: `/27` (27 usable IPs) - e.g., `10.3.0.64/27`
  - Management subnet: `/28` (11 usable IPs) - e.g., `10.3.0.96/28`

#### Security Considerations

- **Network isolation**: Ensure proper network segmentation between AI Services and other resources
- **Access control**: Implement Azure RBAC for resource access
- **Secret management**: Use Azure Key Vault for API keys and connection strings
- **Monitoring**: Enable Azure Monitor and Log Analytics for security monitoring

#### Tools and CLI Requirements

- **Azure CLI** (latest version) or **Azure PowerShell**
- **Docker** with Azure Container Registry integration
- **kubectl** (if deploying to Azure Kubernetes Service)
- **Terraform** or **Bicep** (recommended for Infrastructure as Code)

## Quick Start

1. **Install Harbor**: Run `.\harbor.ps1` to set up the local registry
2. **Configure environment**: Update `env-vars.ps1` with your Azure endpoints and API keys
3. **Pull/Push images**: Run `.\pullpush-ai-svc-images.ps1` to download and mirror container images
4. **Deploy services**: Use `docker-compose.yaml` to run disconnected containers

## Detailed Setup Instructions

### 1. Install and Configure Harbor

Harbor serves as your local container registry for storing AI Services images in disconnected environments.

#### Installation Steps

1. **Run the Harbor installation script**:
   ```powershell
   .\harbor.ps1
   ```

   This script will:
   - Download Harbor v2.13.2 (latest stable version)
   - Extract the installation files to `C:\tools\harbor`
   - Set up the configuration template

2. **Configure Harbor settings**:
   - Edit `harbor.yml` using the provided `harbor.example.yml` template
   - Key configuration options:
     - **hostname**: `localhost` (for local deployment)
     - **http.port**: `8080` (web UI access)
     - **harbor_admin_password**: Change from default `Harbor12345`
     - **data_volume**: `/data` (storage location)

3. **Start Harbor**:
   ```bash
   # Using WSL or bash
   ./install.sh
   
   # Or using Docker Compose directly
   docker compose up -d
   ```

4. **Verify installation**:
   - Access Harbor UI at: `http://localhost:8080`
   - Login with: `admin/Harbor12345` (or your custom password)
   - Confirm the registry is accessible at: `localhost:8090`

#### Testing Harbor Registry

```powershell
# Login to Harbor registry
docker login localhost:8090

# Test with a sample image
docker pull curlimages/curl:latest
docker tag curlimages/curl:latest localhost:8090/library/curlimages/curl:latest
docker push localhost:8090/library/curlimages/curl:latest
```

### 2. Pull/Push AI Services Container Images

The repository includes scripts to automatically pull AI Services images from MCR and push them to your local Harbor registry.

The container repositories are stored in the `ai-services.jsonc` file, along with the required tags. Typically, we include the `latest` and specific version(s).  

For example, this is the configuration for Document Intelligence `read-4.0` image (as of Sep 2025):

```jsonc
{
  "image": "mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0",
  "tags": [
    "latest",
    "2024-11-30",
    "2024-11-30.20250828.1-26420265"
  ]
}
```

#### Available Images

The solution supports multiple AI Services (see [Microsoft Docs](https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-container-support) for full list):

- **Document Intelligence (Form Recognizer)**:
  - Layout recognition
  - Read (OCR)
  - Business cards
  - Custom models
  - ID documents
  - Invoices
  - Receipts

See this link for more information:
<br/>
https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/containers/disconnected?view=doc-intel-4.0.0

- **Language Services**:
  - Text Analytics (Sentiment Analysis)
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/sentiment-opinion-mining/how-to/use-containers

  This image has multiple language tags, e.g.:
  - `3.0-en`
  - `3.0-fr`
  - `3.0-zh`
  ...
  <br/>

  They are stored in `sentiment-tags.csv` file. Any new languages added by Microsoft can be added to this file.

  
  - Text Language Detection
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/language-detection/how-to/use-containers
  
  - Keyphrase Extraction
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/key-phrase-extraction/how-to/use-containers
  
  - Named Entity Recognition
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/named-entity-recognition/how-to/use-containers
  
  - Custom Named Entity Recognition
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/custom-named-entity-recognition/how-to/use-containers
  
  - PII Detection
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/personally-identifiable-information/how-to/use-containers
  
  - Summarization
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/language-service/summarization/how-to/use-containers
  
  - Translator
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/translator/containers/translator-how-to-install-container
  
  - Language Understanding
   <br/>
   https://learn.microsoft.com/en-us/azure/ai-services/luis/luis-container-howto
   - Conversational Language Understanding
   <br/>
   https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/how-to/use-containers


- **Speech Services**:
  - Speech-to-Text
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-container-stt

  This image has multiple language tags, e.g.:
  - `5.0.3-preview-amd64-en-us`
  - `5.0.3-preview-amd64-fr-fr`
  - `5.0.3-preview-amd64-zh-cn`
  ...
  <br/>

  They are stored in `speech-to-text-tags.csv` file. Any new languages added by Microsoft can be added to this file.

  - Custom Speech-to-Text
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-container-cstt

  - Neural Text-to-Speech
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-container-ntts

  This image has multiple language/voice tags, e.g.:
  - `latest`
  - `3.12.0-amd64-zh-cn-xiaoxiaoneural`
  - `3.12.0-amd64-en-us-jennyneural`
  ...
  <br/>

  They are stored in `neural-text-to-speech-tags.csv` file. Any new voices added by Microsoft can be added to this file.

  - Speech Language Detection
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/speech-service/speech-container-lid

- **Vision:**
  - Read OCR
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/computer-vision-how-to-install-containers

  - Spatial Analysis
  <br/>
  https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/spatial-analysis-container

#### Pulling Images

1. **Configure target registry**:
   ```powershell
   $harborRegistry = 'localhost:8090'
   docker login $harborRegistry
   ```

2. **Run the image pull/push script**:
   ```powershell
   # Pull all supported AI Services images
   .\pullpush-ai-svc-images.ps1
   
   # Or pull specific image categories (edit the script to uncomment desired sections)
   ```

3. **Monitor progress**:
   - The script provides real-time progress updates
   - Summary report shows successful/failed pulls
   - Individual image pull status is displayed

#### Manual Image Pull (Alternative)

```powershell
# Load the PullPush function
. .\PullPush-AISvcImage.ps1

# Pull specific images
PullPush-AISvcImage -ImageName "mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-4.0" -Tags @("latest") -TargetRegistry "localhost:8090"
```

### 3. Download License Files and Language Models

#### Environment Configuration

1. **Set up environment variables**:
   ```powershell
   # Edit env-vars.ps1 with your Azure service endpoints and API keys
   .\env-vars.ps1
   ```

   Required variables:
   - `MNGENV_DOCINTEL_ENDPOINT_URI`: Document Intelligence endpoint
   - `MNGENV_DOCINTEL_API_KEY`: Document Intelligence API key
   - `MNGENV_TRANSLATOR_ENDPOINT_URI`: Translator service endpoint
   - `MNGENV_TRANSLATOR_API_KEY`: Translator service API key

#### Language Model Files

The repository includes language support files:

- **`iso_639-1.json`**: ISO language codes for text analytics
- **`locale-languages.csv`**: Locale mappings for speech services
- **`text-to-speech-tags.csv`**: Available TTS voice tags

#### Language-Specific Images

Some services require language-specific container images:

- **Speech-to-Text**: Separate images per language/locale
- **Text Analytics**: Language-specific sentiment models
- **Text-to-Speech**: Individual images per voice

### 4. Run AI Services Disconnected Containers

#### Using Docker Compose

1. **Configure the compose file**:
   Edit `docker-compose.yaml` with your specific requirements:

   ```yaml
   services:
     azure-form-recognizer-layout:
       container_name: azure-form-recognizer-layout
       image: localhost:8090/library/mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-4.0:latest
       environment:
         - EULA=accept
         - billing=${MNGENV_DOCINTEL_ENDPOINT_URI}
         - apiKey=${MNGENV_DOCINTEL_API_KEY}
       ports:
         - "5000:5000"
   ```

2. **Start the services**:
   ```powershell
   docker compose up -d
   ```

3. **Verify services**:
   ```powershell
   # Check container status
   docker ps
   
   # View logs
   docker logs azure-form-recognizer-layout
   
   # Test API endpoint
   curl http://localhost:5000/swagger
   ```

#### Manual Container Deployment

```powershell
# Example: Run Document Intelligence Layout service
docker run -d \
  --name azure-form-recognizer-layout \
  -p 5000:5000 \
  -e EULA=accept \
  -e billing=$env:MNGENV_DOCINTEL_ENDPOINT_URI \
  -e apiKey=$env:MNGENV_DOCINTEL_API_KEY \
  localhost:8090/library/mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-4.0:latest
```

## Configuration Files

### Key Files Description

- **`harbor.ps1`**: Harbor installation and setup script
- **`harbor.example.yml`**: Harbor configuration template
- **`pullpush-ai-svc-images.ps1`**: Main script to pull/push AI Services images
- **`PullPush-AISvcImage.ps1`**: Core function for image operations
- **`ai-services.jsonc`**: Catalog of available AI Services images and tags
- **`docker-compose.yaml`**: Container orchestration configuration
- **`env-vars.ps1`**: Environment variables setup script

### Language and Locale Files

- **`iso_639-1.json`**: ISO language codes
- **`locale-languages.csv`**: Speech service locale mappings
- **`text-to-speech-tags.csv`**: TTS voice tags
- **`List-LocaleLanguageCountry.ps1`**: Utility script for locale information

## Troubleshooting

### Common Issues

1. **Harbor not accessible**:
   - Verify Docker is running
   - Check port 8080/8090 are not in use
   - Confirm firewall settings

2. **Image pull failures**:
   - Verify internet connectivity
   - Check Docker Hub rate limits
   - Ensure sufficient disk space

3. **Container startup issues**:
   - Verify environment variables are set
   - Check API key validity
   - Review container logs

### Useful Commands

```powershell
# Check Harbor status
docker ps | findstr harbor

# View container logs
docker logs <container-name>

# List pulled images
docker images | findstr azure-cognitive-services

# Check disk usage
docker system df

# Clean up unused resources
docker system prune
```

## Security Considerations

- Change default Harbor admin password
- Store API keys securely (consider using Azure Key Vault)
- Implement proper network isolation for disconnected environments
- Regularly update container images for security patches

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

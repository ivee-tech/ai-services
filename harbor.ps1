# Create a directory for Harbor
cd C:\tools\habor

# Download the latest Harbor release (replace with the latest version)
$harborVersion = "v2.13.2"
$downloadUrl = "https://github.com/goharbor/harbor/releases/download/$harborVersion/harbor-offline-installer-$harborVersion.tgz"
Invoke-WebRequest -Uri $downloadUrl -OutFile "harbor-offline-installer-$harborVersion.tgz"

# Extract the archive (you may need 7-Zip or similar)
# If you have tar available in Windows:
tar -xzf "harbor-offline-installer-$harborVersion.tgz"

# Navigate to the harbor directory
cd harbor

# Copy the configuration template
Copy-Item harbor.yml.tmpl harbor.yml

# Edit harbor.yml with your preferred text editor
code harbor.yml
# use harbor.example.yml

# Run the Harbor installer (use wsl)
.\install.sh

# If you don't have bash, you can use PowerShell to run Docker Compose directly:
# docker compose up -d


# access the registry at http://localhost:8080
# login with admin/Harbor12345

# test the registry
# Login to your Harbor registry
docker login localhost:8090

# Tag and push a test image
$img = 'curlimages/curl:latest'
docker tag $img localhost:8090/library/$img
docker push localhost:8090/library/$img

param (
    [Parameter(Mandatory=$false)]
    [string]$DockerHubUsername = "sandarusndr"
)

Write-Host "Deploying to local K3s cluster using Docker Hub username: $DockerHubUsername" -ForegroundColor Cyan

# Create a temporary directory for modified manifests
$tempDir = Join-Path $env:TEMP "k8s_deploy"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy and modify YAML files
$k8sDir = Join-Path $PSScriptRoot "k8s"
Get-ChildItem -Path $k8sDir -Filter "*.yaml" | ForEach-Object {
    $content = Get-Content $_.FullName
    $modifiedContent = $content -replace "DOCKERHUB_USERNAME_PLACEHOLDER", $DockerHubUsername
    $newFilePath = Join-Path $tempDir $_.Name
    Set-Content -Path $newFilePath -Value $modifiedContent
}

Write-Host "Applying manifests..." -ForegroundColor Green
kubectl apply -f "$tempDir/namespace.yaml"
kubectl apply -f "$tempDir/configmap.yaml"
kubectl apply -f "$tempDir/rabbitmq.yaml"
kubectl apply -f "$tempDir/scheduling-service.yaml"
kubectl apply -f "$tempDir/attendance-service.yaml"
kubectl apply -f "$tempDir/ai-vision-service.yaml"
kubectl apply -f "$tempDir/traefik-middleware.yaml"
kubectl apply -f "$tempDir/ingress.yaml"

Write-Host "Restarting deployments to pull latest images..." -ForegroundColor Green
kubectl rollout restart deployment/scheduling-service -n smart-attendance
kubectl rollout restart deployment/attendance-service -n smart-attendance
kubectl rollout restart deployment/ai-vision-service -n smart-attendance

Write-Host "Deployment completed successfully!" -ForegroundColor Green

# Clean up temp directory
Remove-Item -Recurse -Force $tempDir

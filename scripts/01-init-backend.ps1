[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string]$Prefix = "tfstate"
)

$ErrorActionPreference = "Stop"

$ResourceGroupName = "rg-terraform-backend"
$ContainerName     = "tfstate"
$LockName          = "lock-terraform-backend"

$RandomSuffix      = -join ((97..122) + (48..57) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$StorageAccountName = "st$Prefix$RandomSuffix"
if ($StorageAccountName.Length -gt 24) {
    $StorageAccountName = $StorageAccountName.Substring(0, 24)
}

function Test-Prerequisites {
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        Write-Host "Suscripcion activa: $($account.name) ($($account.id))"
    }
    catch {
        Write-Host "Iniciando login en Azure CLI..."
        az login
    }
}

function New-BackendResourceGroup {
    $existing = az group show --name $ResourceGroupName 2>$null
    if (-not $existing) {
        az group create `
            --name $ResourceGroupName `
            --location $Location `
            --output none
        Write-Host "Resource Group creado: $ResourceGroupName"
    }
}

function New-BackendStorageAccount {
    $existing = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName 2>$null
    if (-not $existing) {
        az storage account create `
            --name $StorageAccountName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --sku "Standard_LRS" `
            --kind "StorageV2" `
            --access-tier "Hot" `
            --min-tls-version "TLS1_2" `
            --allow-blob-public-access false `
            --https-only true `
            --output none
        Write-Host "Storage Account creada: $StorageAccountName"
    }

    az storage account blob-service-properties update `
        --account-name $StorageAccountName `
        --resource-group $ResourceGroupName `
        --enable-versioning true `
        --output none
}

function New-BackendBlobContainer {
    $storageKey = (az storage account keys list `
        --account-name $StorageAccountName `
        --resource-group $ResourceGroupName `
        --query '[0].value' -o tsv)

    $existing = az storage container show `
        --name $ContainerName `
        --account-name $StorageAccountName `
        --account-key $storageKey 2>$null
    if (-not $existing) {
        az storage container create `
            --name $ContainerName `
            --account-name $StorageAccountName `
            --account-key $storageKey `
            --output none
        Write-Host "Blob Container creado: $ContainerName"
    }
}

function New-BackendResourceLock {
    $existing = az lock show --name $LockName --resource-group $ResourceGroupName 2>$null
    if (-not $existing) {
        az lock create `
            --name $LockName `
            --resource-group $ResourceGroupName `
            --lock-type CanNotDelete `
            --notes "Proteccion de estado Terraform" `
            --output none
    }
}

function Write-Summary {
    Write-Host "Backend configurado."
    Write-Host "Resource Group:  $ResourceGroupName"
    Write-Host "Storage Account: $StorageAccountName"
    Write-Host "Container:       $ContainerName"

    $configPath = Join-Path (Split-Path $PSScriptRoot) ".backend-config"
    $configContent = @"
BACKEND_RESOURCE_GROUP="$ResourceGroupName"
BACKEND_STORAGE_ACCOUNT="$StorageAccountName"
BACKEND_CONTAINER="$ContainerName"
BACKEND_LOCATION="$Location"
BACKEND_STATE_KEY="infraestructura.tfstate"
"@
    Set-Content -Path $configPath -Value $configContent -Encoding UTF8
}

Test-Prerequisites
New-BackendResourceGroup
New-BackendStorageAccount
New-BackendBlobContainer
New-BackendResourceLock
Write-Summary


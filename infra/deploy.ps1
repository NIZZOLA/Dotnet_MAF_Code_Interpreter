#requires -Version 7.0
<#
.SYNOPSIS
  Provisiona a infraestrutura do ExcelInsights no Azure (conta Foundry + projeto +
  deployment de modelo + RBAC) e imprime os valores para o appsettings.json.

.EXAMPLE
  ./deploy.ps1 -ResourceGroup rg-excelinsights -Location eastus -FoundryAccountName foundry-xlsx-001

.NOTES
  Requer Azure CLI autenticada (az login) com permissão de escrita de role assignments
  no escopo, se -AssignRoles $true (padrão). Caso contrário, use -AssignRoles $false e
  peça a um admin para conceder o papel Foundry User depois.
#>
param(
    [string]$ResourceGroup = 'rg-excelinsights',
    [string]$Location = 'eastus',

    # Precisa ser único no domínio *.services.ai.azure.com
    [string]$FoundryAccountName = "foundry-xlsx-$(Get-Random -Maximum 99999)",

    [string]$ProjectName = 'proj-excelinsights',
    [string]$ModelDeploymentName = 'gpt-4o',
    [string]$ModelName = 'gpt-4o',
    [string]$ModelVersion = '2024-11-20',
    [int]$ModelCapacity = 50,
    [string]$ModelSkuName = 'GlobalStandard',

    [bool]$AssignRoles = $true
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Assinatura ativa:" -ForegroundColor Cyan
az account show --query "{name:name, id:id, tenant:tenantId}" -o table

# Object id do usuário logado, para liberar o data plane ao seu próprio usuário.
$appPrincipalId = az ad signed-in-user show --query id -o tsv
Write-Host "==> Usuário logado (object id): $appPrincipalId" -ForegroundColor Cyan

Write-Host "==> Criando resource group '$ResourceGroup' em '$Location'..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location --output none

Write-Host "==> Deploy Bicep (conta='$FoundryAccountName', modelo='$ModelName')..." -ForegroundColor Cyan
$deployment = az deployment group create `
    --resource-group $ResourceGroup `
    --name "excelinsights-$(Get-Random -Maximum 99999)" `
    --template-file (Join-Path $scriptDir 'main.bicep') `
    --parameters `
        location=$Location `
        foundryAccountName=$FoundryAccountName `
        projectName=$ProjectName `
        modelDeploymentName=$ModelDeploymentName `
        modelName=$ModelName `
        modelVersion=$ModelVersion `
        modelCapacity=$ModelCapacity `
        modelSkuName=$ModelSkuName `
        assignRoles=$AssignRoles `
        appPrincipalId=$appPrincipalId `
        appPrincipalType=User `
    --query properties.outputs `
    -o json | ConvertFrom-Json

$projectEndpoint = $deployment.projectEndpoint.value
$modelDeployment = $deployment.modelDeployment.value

Write-Host ""
Write-Host "===================== DEPLOY CONCLUÍDO =====================" -ForegroundColor Green
Write-Host "Atualize src/ExcelInsights/appsettings.json com:" -ForegroundColor Green
Write-Host ""
Write-Host "  `"ProjectEndpoint`": `"$projectEndpoint`","
Write-Host "  `"ModelDeployment`": `"$modelDeployment`","
Write-Host ""
Write-Host "Depois: cd ../src/ExcelInsights ; dotnet run" -ForegroundColor Green
Write-Host "(RBAC pode levar alguns minutos para propagar.)" -ForegroundColor DarkYellow

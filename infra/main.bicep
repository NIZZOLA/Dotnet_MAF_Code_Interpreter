// =============================================================================
// main.bicep — provisiona a infraestrutura da aplicação ExcelInsights.
//
// Escopo: Resource Group. Crie o RG antes (o deploy.ps1 já faz isso) ou use
//   az deployment group create -g <rg> --template-file main.bicep --parameters main.bicepparam
//
// Recursos: conta Foundry (AIServices) + projeto + deployment de modelo,
//   e (opcional) as atribuições de papel Foundry User.
// =============================================================================

targetScope = 'resourceGroup'

@description('Região dos recursos.')
param location string = resourceGroup().location

@description('Nome da conta Foundry (Cognitive Services / AIServices). Precisa ser único no domínio.')
@minLength(3)
@maxLength(63)
param foundryAccountName string

@description('Nome do projeto Foundry.')
param projectName string = 'proj-excelinsights'

@description('Nome de exibição do projeto no portal.')
param projectDisplayName string = 'ExcelInsights'

@description('Nome do deployment do modelo (usado em Foundry:ModelDeployment na app).')
param modelDeploymentName string = 'gpt-4o'

@description('Modelo do catálogo. Precisa suportar Code Interpreter (ex.: gpt-4o, gpt-4.1, gpt-5-mini).')
param modelName string = 'gpt-4o'

@description('Versão do modelo. Vazio = versão padrão do serviço.')
param modelVersion string = '2024-11-20'

@description('Capacidade do deployment em milhares de TPM.')
@minValue(1)
param modelCapacity int = 50

@description('SKU do deployment.')
param modelSkuName string = 'GlobalStandard'

@description('Se true, cria as atribuições de papel Foundry User (exige permissão de escrita em RBAC).')
param assignRoles bool = true

@description('Object id do usuário/SP que roda a app (para o data plane). Vazio = só a MI do projeto.')
param appPrincipalId string = ''

@description('Tipo do principal da app.')
@allowed([
  'User'
  'ServicePrincipal'
])
param appPrincipalType string = 'User'

@description('Tags aplicadas aos recursos.')
param tags object = {
  app: 'ExcelInsights'
  stack: 'agent-framework-foundry'
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    foundryAccountName: foundryAccountName
    projectName: projectName
    projectDisplayName: projectDisplayName
    modelDeploymentName: modelDeploymentName
    modelName: modelName
    modelVersion: modelVersion
    modelCapacity: modelCapacity
    modelSkuName: modelSkuName
    tags: tags
  }
}

module roles 'modules/roleAssignments.bicep' = if (assignRoles) {
  name: 'roleAssignments'
  params: {
    foundryAccountName: foundry.outputs.accountName
    projectPrincipalId: foundry.outputs.projectPrincipalId
    appPrincipalId: appPrincipalId
    appPrincipalType: appPrincipalType
  }
}

@description('Endpoint do projeto — cole em Foundry:ProjectEndpoint no appsettings.json.')
output projectEndpoint string = foundry.outputs.projectEndpoint

@description('Nome do deployment — cole em Foundry:ModelDeployment no appsettings.json.')
output modelDeployment string = foundry.outputs.modelDeploymentName

@description('Nome da conta Foundry criada.')
output foundryAccountName string = foundry.outputs.accountName

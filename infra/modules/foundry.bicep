// =============================================================================
// Foundry (Azure AI Foundry) — conta + projeto + deployment de modelo
// Recursos para rodar a aplicação ExcelInsights (Code Interpreter sobre xlsx).
// =============================================================================

@description('Região dos recursos (deve suportar Foundry Agents + Code Interpreter e o modelo escolhido).')
param location string

@description('Nome da conta Foundry (Cognitive Services / AIServices). Vira também o subdomínio.')
@minLength(3)
@maxLength(63)
param foundryAccountName string

@description('Nome do projeto Foundry (usado no endpoint /api/projects/<nome>).')
param projectName string

@description('Nome de exibição do projeto no portal Foundry.')
param projectDisplayName string

@description('Nome do deployment do modelo (é o que a app usa em Foundry:ModelDeployment).')
param modelDeploymentName string

@description('Nome do modelo no catálogo (ex.: gpt-4o, gpt-4.1, gpt-5-mini).')
param modelName string

@description('Versão do modelo. Vazio = versão padrão atribuída pelo serviço.')
param modelVersion string

@description('Capacidade do deployment em milhares de tokens/min (TPM).')
param modelCapacity int

@description('SKU do deployment (ex.: GlobalStandard, Standard, DataZoneStandard).')
param modelSkuName string

@description('Tags aplicadas aos recursos.')
param tags object

// ---------------------------------------------------------------------------
// Conta Foundry (kind = AIServices) com gerenciamento de projetos habilitado
// ---------------------------------------------------------------------------
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Habilita projetos como recursos-filho (modelo do Foundry Agent Service).
    allowProjectManagement: true
    // Subdomínio custom é obrigatório para autenticação via Entra ID (token).
    customSubDomainName: foundryAccountName
    publicNetworkAccess: 'Enabled'
    // Mantém auth por chave habilitada além do Entra ID; a app usa Entra ID.
    disableLocalAuth: false
  }
}

// ---------------------------------------------------------------------------
// Projeto Foundry (contexto de agentes, arquivos e code interpreter)
// ---------------------------------------------------------------------------
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: account
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: 'Projeto que hospeda o agente ExcelInsights com Code Interpreter.'
  }
}

// ---------------------------------------------------------------------------
// Deployment do modelo usado pelo agente
// ---------------------------------------------------------------------------
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: account
  name: modelDeploymentName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: empty(modelVersion) ? null : modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  // Serializa a criação dos filhos da conta para evitar conflito de escrita concorrente.
  dependsOn: [
    project
  ]
}

@description('Nome da conta Foundry criada.')
output accountName string = account.name

@description('Resource id da conta Foundry (escopo para role assignments).')
output accountId string = account.id

@description('Nome do projeto criado.')
output projectName string = project.name

@description('Principal id da managed identity do projeto (precisa do papel Foundry User).')
output projectPrincipalId string = project.identity.principalId

@description('Endpoint do projeto no formato consumido pela aplicação.')
output projectEndpoint string = 'https://${account.name}.services.ai.azure.com/api/projects/${project.name}'

@description('Nome do deployment do modelo (usar em Foundry:ModelDeployment).')
output modelDeploymentName string = modelDeployment.name

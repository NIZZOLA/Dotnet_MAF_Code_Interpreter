// =============================================================================
// Atribuições de papel (RBAC) para a aplicação ExcelInsights.
//
// O papel "Foundry User" (antigo Azure AI User) concede as data actions
// Microsoft.CognitiveServices/accounts/AIServices/agents/* — necessárias para
// criar/executar agentes (agents/write) via Code Interpreter.
//
// Concede o papel, no escopo da conta Foundry, para:
//   1. A managed identity do PROJETO (executa agents/write no backend).
//   2. O usuário/serviço que roda a aplicação (data plane), quando informado.
// =============================================================================

@description('Nome da conta Foundry onde os papéis são atribuídos.')
param foundryAccountName string

@description('Principal id da managed identity do projeto.')
param projectPrincipalId string

@description('Object id do usuário ou service principal que executa a app. Vazio = não atribui.')
param appPrincipalId string = ''

@description('Tipo do principal da app: User (dev local via az login) ou ServicePrincipal.')
@allowed([
  'User'
  'ServicePrincipal'
])
param appPrincipalType string = 'User'

// ID fixo do papel built-in "Foundry User" (estável apesar da renomeação).
var foundryUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource foundryUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: foundryUserRoleId
}

// 1. Managed identity do projeto -> Foundry User na conta
resource projectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, projectPrincipalId, foundryUserRoleId)
  scope: account
  properties: {
    roleDefinitionId: foundryUserRole.id
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// 2. Identidade da aplicação -> Foundry User na conta (opcional)
resource appRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appPrincipalId)) {
  name: guid(account.id, appPrincipalId, foundryUserRoleId)
  scope: account
  properties: {
    roleDefinitionId: foundryUserRole.id
    principalId: appPrincipalId
    principalType: appPrincipalType
  }
}

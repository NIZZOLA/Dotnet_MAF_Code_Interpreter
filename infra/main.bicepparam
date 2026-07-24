using 'main.bicep'

// Ajuste os valores abaixo. foundryAccountName precisa ser único (vira subdomínio).
param foundryAccountName = 'foundry-excelinsights-001'
param location = 'eastus'

param projectName = 'proj-excelinsights'
param projectDisplayName = 'ExcelInsights'

// Modelo: precisa suportar Code Interpreter na região escolhida.
param modelDeploymentName = 'gpt-4o'
param modelName = 'gpt-4o'
param modelVersion = '2024-11-20'
param modelCapacity = 50
param modelSkuName = 'GlobalStandard'

// RBAC: deixe assignRoles=true para conceder Foundry User automaticamente.
// Preencha appPrincipalId com seu object id (az ad signed-in-user show --query id -o tsv)
// para também liberar o data plane ao seu usuário. Vazio = só a MI do projeto.
param assignRoles = true
param appPrincipalId = ''
param appPrincipalType = 'User'

namespace ExcelInsights.Configuration;

/// <summary>
/// Configurações de conexão com o projeto do Microsoft Foundry (Azure AI Foundry).
/// Preenchidas via appsettings.json, variáveis de ambiente ou user-secrets.
/// </summary>
public sealed class FoundryOptions
{
    public const string SectionName = "Foundry";

    /// <summary>
    /// Endpoint do projeto no formato:
    /// https://{recurso}.services.ai.azure.com/api/projects/{projeto}
    /// </summary>
    public string ProjectEndpoint { get; set; } = string.Empty;

    /// <summary>Nome do deployment do modelo (ex.: "gpt-5-mini", "gpt-4o").</summary>
    public string ModelDeployment { get; set; } = "gpt-5-mini";

    /// <summary>Nome lógico dado ao agente.</summary>
    public string AgentName { get; set; } = "ExcelInsightsAgent";

    /// <summary>
    /// Como autenticar no Foundry:
    /// <list type="bullet">
    /// <item><c>azurecli</c> — usa o login do `az login` (recomendado em dev local; evita a sondagem lenta do IMDS).</item>
    /// <item><c>managedidentity</c> — Managed Identity (produção em Azure).</item>
    /// <item><c>default</c> — DefaultAzureCredential (cadeia completa de credenciais).</item>
    /// </list>
    /// </summary>
    public string CredentialMode { get; set; } = "azurecli";
}

/// <summary>Configurações relacionadas à planilha e à sua documentação.</summary>
public sealed class SpreadsheetOptions
{
    public const string SectionName = "Spreadsheet";

    /// <summary>Caminho local do arquivo .xlsx que será enviado ao Code Interpreter.</summary>
    public string FilePath { get; set; } = string.Empty;

    /// <summary>Caminho do arquivo markdown com a documentação das abas/colunas.</summary>
    public string InstructionsPath { get; set; } = "Prompts/spreadsheet-instructions.md";
}

using Azure.AI.Projects;
using ExcelInsights.Agents;
using ExcelInsights.Configuration;
using ExcelInsights.Services;
using Microsoft.Agents.AI;
using Microsoft.Extensions.Configuration;

// ---------------------------------------------------------------------------
// 1. Configuração (appsettings.json + variáveis de ambiente + user-secrets)
// ---------------------------------------------------------------------------
IConfiguration config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false)
    .AddEnvironmentVariables()
    .AddUserSecrets(typeof(Program).Assembly, optional: true)
    .Build();

var foundry = config.GetSection(FoundryOptions.SectionName).Get<FoundryOptions>()
    ?? throw new InvalidOperationException("Seção 'Foundry' ausente na configuração.");
var spreadsheet = config.GetSection(SpreadsheetOptions.SectionName).Get<SpreadsheetOptions>()
    ?? throw new InvalidOperationException("Seção 'Spreadsheet' ausente na configuração.");

// Encerramento gracioso com Ctrl+C.
using var cts = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => { e.Cancel = true; cts.Cancel(); };

// ---------------------------------------------------------------------------
// 2. Cliente do projeto Foundry
//    A credencial é escolhida por Foundry:CredentialMode (padrão "azurecli",
//    que usa o `az login` e evita a sondagem lenta do IMDS em dev local).
// ---------------------------------------------------------------------------
var projectClient = new AIProjectClient(
    endpoint: new Uri(foundry.ProjectEndpoint),
    tokenProvider: CredentialFactory.Create(foundry.CredentialMode));

// ---------------------------------------------------------------------------
// 3. Carrega a documentação da planilha (instruções do agente) e envia o arquivo
// ---------------------------------------------------------------------------
string instructionsPath = Path.Combine(AppContext.BaseDirectory, spreadsheet.InstructionsPath);
string instructions = await File.ReadAllTextAsync(instructionsPath, cts.Token);

var uploadService = new FileUploadService(projectClient);

Console.WriteLine("Enviando planilha para o Foundry...");
string fileId = await uploadService.UploadAsync(spreadsheet.FilePath, cts.Token);
Console.WriteLine($"Planilha enviada (file-id: {fileId}).");

// ---------------------------------------------------------------------------
// 4. Cria o agente com Code Interpreter + planilha anexada e inicia a conversa
// ---------------------------------------------------------------------------
try
{
    var factory = new ExcelAgentFactory(projectClient, foundry);
    AIAgent agent = factory.Create(instructions, fileId);

    var loop = new ConversationLoop(agent);
    await loop.RunAsync(cts.Token);
}
finally
{
    // Limpa o arquivo no Foundry ao encerrar.
    try { await uploadService.DeleteAsync(fileId, CancellationToken.None); }
    catch { /* melhor esforço */ }

    Console.WriteLine("\nEncerrado.");
}

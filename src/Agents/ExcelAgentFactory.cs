using Azure.AI.Projects;
using ExcelInsights.Configuration;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace ExcelInsights.Agents;

/// <summary>
/// Cria o <see cref="AIAgent"/> (padrão "Hosted Agent" do Microsoft Agent Framework)
/// configurado com a ferramenta Code Interpreter e a planilha já anexada.
/// </summary>
public sealed class ExcelAgentFactory(AIProjectClient projectClient, FoundryOptions options)
{
    private readonly AIProjectClient _projectClient = projectClient;
    private readonly FoundryOptions _options = options;

    /// <summary>
    /// Monta o agente. As <paramref name="instructions"/> devem conter a documentação
    /// das abas e colunas da planilha (o "prompt específico"), e <paramref name="fileId"/>
    /// é o arquivo já enviado ao Foundry via <see cref="Services.FileUploadService"/>.
    /// </summary>
    public AIAgent Create(string instructions, string fileId)
    {
        // A ferramenta hospedada roda Python num sandbox gerenciado pelo Foundry.
        // Ao informar o file-id em Inputs, a planilha fica disponível no ambiente
        // para o modelo ler (ex.: pandas.read_excel) e responder às perguntas.
        var codeInterpreter = new HostedCodeInterpreterTool
        {
            Inputs = [new HostedFileContent(fileId)]
        };

        return _projectClient.AsAIAgent(
            _options.ModelDeployment,
            instructions: instructions,
            name: _options.AgentName,
            tools: [codeInterpreter]);
    }
}

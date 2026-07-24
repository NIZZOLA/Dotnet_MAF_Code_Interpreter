using Azure.AI.Projects;
using OpenAI.Files;

namespace ExcelInsights.Services;

/// <summary>
/// Envia a planilha para o Foundry usando o file client compatível com OpenAI.
/// O arquivo enviado com <see cref="FileUploadPurpose.Assistants"/> pode então ser
/// referenciado pela ferramenta Code Interpreter para leitura no sandbox Python.
/// </summary>
public sealed class FileUploadService(AIProjectClient projectClient)
{
    private readonly AIProjectClient _projectClient = projectClient;

    /// <summary>
    /// Faz o upload do arquivo local e retorna o identificador (file-id) atribuído pelo Foundry.
    /// </summary>
    public async Task<string> UploadAsync(string filePath, CancellationToken ct = default)
    {
        if (!File.Exists(filePath))
        {
            throw new FileNotFoundException(
                $"Planilha não encontrada em '{Path.GetFullPath(filePath)}'. " +
                "Verifique a chave Spreadsheet:FilePath no appsettings.json.", filePath);
        }

        OpenAIFileClient fileClient = _projectClient.ProjectOpenAIClient.GetOpenAIFileClient();

        // FileUploadPurpose.Assistants é o "purpose" exigido para uso com Code Interpreter.
        // Usamos a sobrecarga com Stream por aceitar CancellationToken.
        await using FileStream stream = File.OpenRead(filePath);
        OpenAIFile uploaded = await fileClient.UploadFileAsync(
            file: stream,
            filename: Path.GetFileName(filePath),
            purpose: FileUploadPurpose.Assistants,
            cancellationToken: ct);

        return uploaded.Id;
    }

    /// <summary>Remove o arquivo do Foundry ao final da sessão (evita acúmulo de storage).</summary>
    public async Task DeleteAsync(string fileId, CancellationToken ct = default)
    {
        OpenAIFileClient fileClient = _projectClient.ProjectOpenAIClient.GetOpenAIFileClient();
        await fileClient.DeleteFileAsync(fileId, ct);
    }
}

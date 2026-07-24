using System.Text;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace ExcelInsights.Services;

/// <summary>
/// Interface conversacional de terminal. Mantém uma <see cref="AgentSession"/> viva
/// (memória de turnos) e envia cada pergunta do usuário ao agente com Code Interpreter.
/// </summary>
public sealed class ConversationLoop(AIAgent agent)
{
    private readonly AIAgent _agent = agent;

    public async Task RunAsync(CancellationToken ct = default)
    {
        AgentSession session = await _agent.CreateSessionAsync(ct);

        Console.WriteLine();
        Console.WriteLine("Assistente de planilha pronto. Faça perguntas sobre os dados.");
        Console.WriteLine("Comandos: /code liga/desliga a exibição do Python gerado | /sair encerra.");
        Console.WriteLine(new string('-', 70));

        bool showCode = false;

        while (!ct.IsCancellationRequested)
        {
            Console.Write("\nVocê> ");
            string? question = Console.ReadLine();

            if (string.IsNullOrWhiteSpace(question))
                continue;

            switch (question.Trim().ToLowerInvariant())
            {
                case "/sair":
                case "/exit":
                case "/quit":
                    return;
                case "/code":
                    showCode = !showCode;
                    Console.WriteLine($"[exibição de código: {(showCode ? "ligada" : "desligada")}]");
                    continue;
            }

            try
            {
                AgentResponse response = await _agent.RunAsync(question, session, cancellationToken: ct);

                if (showCode)
                    PrintCodeInterpreterTrace(response);

                Console.WriteLine($"\nAssistente> {response.Text}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n[erro] {ex.Message}");
            }
        }
    }

    /// <summary>Mostra o código Python que o Code Interpreter escreveu e o resultado da execução.</summary>
    private static void PrintCodeInterpreterTrace(AgentResponse response)
    {
        CodeInterpreterToolCallContent? call = response.Messages
            .SelectMany(m => m.Contents)
            .OfType<CodeInterpreterToolCallContent>()
            .FirstOrDefault();

        if (call?.Inputs?.OfType<DataContent>().FirstOrDefault() is { } code &&
            code.HasTopLevelMediaType("text"))
        {
            Console.WriteLine("\n--- código gerado ---");
            Console.WriteLine(Encoding.UTF8.GetString(code.Data.ToArray()));
            Console.WriteLine("----------------------");
        }

        CodeInterpreterToolResultContent? result = response.Messages
            .SelectMany(m => m.Contents)
            .OfType<CodeInterpreterToolResultContent>()
            .FirstOrDefault();

        if (result?.Outputs?.OfType<TextContent>().FirstOrDefault() is { } output)
        {
            Console.WriteLine($"--- resultado da execução ---\n{output.Text}\n-----------------------------");
        }
    }
}

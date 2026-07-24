# Excel Insights

Aplicação de console desenvolvida em .NET 9 para analisar arquivos Excel de forma inteligente usando Microsoft Agent Framework e Azure AI Foundry.

A ferramenta permite conversar com uma planilha em linguagem natural, enviando perguntas como “qual foi o faturamento total do mês?” ou “quais produtos tiveram maior margem?”, enquanto um agente com Code Interpreter executa Python em um ambiente gerenciado para ler o workbook e responder com base nos dados reais.

## O que a aplicação faz

Esta aplicação oferece um fluxo completo para trabalhar com planilhas de forma assistida:

- Envia automaticamente uma planilha `.xlsx` para o projeto do Azure AI Foundry.
- Cria um agente especializado para interpretar a planilha e responder perguntas.
- Usa o recurso de Code Interpreter para executar Python e analisar os dados contidos na planilha.
- Suporta perguntas em linguagem natural sobre múltiplas abas e colunas.
- Permite definir instruções específicas da planilha em um arquivo Markdown, incluindo regras de negócio e dicionário de dados.
- Mantém uma conversa interativa no terminal, com comandos para controlar a experiência.

## Principais funcionalidades

### 1. Análise conversacional de planilhas
O usuário pode fazer perguntas diretamente no terminal e o agente interpreta a planilha para responder com base em cálculos e leitura dos dados.

### 2. Uso de Code Interpreter
A aplicação utiliza um agente com suporte a Code Interpreter, permitindo:
- leitura de arquivos Excel com `pandas`/`openpyxl`;
- execução de cálculos e agregações;
- geração de respostas baseadas em dados reais.

### 3. Instruções personalizadas por planilha
O comportamento do agente pode ser guiado por um arquivo de instruções (`Prompts/spreadsheet-instructions.md`), o que permite:
- descrever as abas e colunas da planilha;
- informar regras de negócio;
- orientar o agente sobre como interpretar os dados corretamente.

### 4. Configuração flexível
As configurações podem ser fornecidas via:
- `appsettings.json`;
- variáveis de ambiente;
- user secrets.

Isso permite separar facilmente os dados de conexão e o caminho da planilha do código fonte.

### 5. Comandos interativos no terminal
Durante a execução, o usuário pode usar:
- `/code` para ativar ou desativar a exibição do código Python gerado;
- `/sair` para encerrar a sessão.

## Tecnologias utilizadas

- .NET 9
- Microsoft Agent Framework
- Azure AI Foundry
- Azure.AI.Projects
- Microsoft.Extensions.Hosting
- Azure.Identity

## Pré-requisitos

Antes de executar a aplicação, certifique-se de que você possui:

- .NET SDK 9 instalado;
- acesso a um projeto no Azure AI Foundry;
- autenticação configurada no Azure (por exemplo, via `az login`);
- uma planilha `.xlsx` válida e o caminho correto configurado.

## Como executar

1. Ajuste o arquivo `src/appsettings.json` com:
   - o endpoint do projeto Foundry;
   - o deployment do modelo;
   - o caminho da planilha;
   - o caminho do arquivo de instruções.

2. Execute a aplicação:

```bash
dotnet run --project src/ExcelInsights.csproj
```

3. Faça perguntas no terminal sobre os dados da planilha.

## Estrutura do projeto

- `src/Program.cs`: ponto de entrada da aplicação.
- `src/Agents/`: criação e configuração do agente.
- `src/Services/`: upload de arquivos, loop de conversa e interação com o terminal.
- `src/Configuration/`: classes de configuração e autenticação.
- `src/Prompts/`: instruções do agente para a planilha.

## Exemplo de uso

Após iniciar a aplicação, pode-se perguntar:

- “Qual foi o faturamento total por região?”
- “Quais produtos tiveram maior margem?”
- “A meta de vendas foi alcançada no mês atual?”

O agente irá analisar a planilha e responder com base nos dados disponíveis.

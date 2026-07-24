using Azure.Core;
using Azure.Identity;

namespace ExcelInsights.Configuration;

/// <summary>
/// Constrói a <see cref="TokenCredential"/> conforme <see cref="FoundryOptions.CredentialMode"/>.
/// Em dev local prefira "azurecli": o DefaultAzureCredential tenta o ManagedIdentityCredential,
/// que sonda o IMDS (169.254.169.254, só existe em VMs Azure) e trava fora do Azure.
/// </summary>
public static class CredentialFactory
{
    public static TokenCredential Create(string mode) => mode?.Trim().ToLowerInvariant() switch
    {
        "managedidentity" => new ManagedIdentityCredential(),
        "default"         => new DefaultAzureCredential(),
        _                 => new AzureCliCredential(), // "azurecli" (padrão)
    };
}

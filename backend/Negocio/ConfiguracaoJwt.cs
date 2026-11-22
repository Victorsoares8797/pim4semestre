using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Buillon.Negocio;

public sealed class ConfiguracaoJwt
{
    public const string Emissor = "Buillon.Api";
    public const string Publico = "Buillon.Clientes";
    public string DiretorioPrivado { get; }
    public SymmetricSecurityKey Chave { get; }

    public ConfiguracaoJwt(string? chave, string diretorioPrivado)
    {
        DiretorioPrivado = diretorioPrivado;
        Directory.CreateDirectory(diretorioPrivado);
        if (string.IsNullOrWhiteSpace(chave))
        {
            var arquivo = Path.Combine(diretorioPrivado, "jwt.key");
            if (!File.Exists(arquivo))
            {
                try
                {
                    using var stream = new FileStream(arquivo, FileMode.CreateNew, FileAccess.Write, FileShare.None);
                    var bytes = Encoding.UTF8.GetBytes(Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)));
                    stream.Write(bytes);
                }
                catch (IOException) when (File.Exists(arquivo)) { }
            }
            chave = File.ReadAllText(arquivo).Trim();
        }
        if (Encoding.UTF8.GetByteCount(chave) < 32)
            throw new InvalidOperationException("Configure Jwt:Key com pelo menos 32 bytes.");
        Chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(chave));
    }

    public TokenValidationParameters ParametrosValidacao() => new()
    {
        ValidateIssuer = true, ValidIssuer = Emissor,
        ValidateAudience = true, ValidAudience = Publico,
        ValidateLifetime = true, RequireExpirationTime = true,
        RequireSignedTokens = true, ValidateIssuerSigningKey = true, IssuerSigningKey = Chave,
        ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
        NameClaimType = ClaimTypes.Name, RoleClaimType = ClaimTypes.Role,
        ClockSkew = TimeSpan.FromSeconds(15)
    };
}

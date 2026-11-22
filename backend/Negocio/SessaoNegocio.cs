using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text.Json;
using Buillon.Modelos;
using Microsoft.IdentityModel.Tokens;

namespace Buillon.Negocio;

// JWT como no código enviado. O arquivo local guarda apenas IDs revogados e suas expirações.
public sealed class SessaoNegocio
{
    private readonly ConfiguracaoJwt _jwt;
    private readonly string _arquivoRevogados;
    private readonly object _cadeado = new();
    private readonly Dictionary<string, DateTime> _revogados;
    private readonly JwtSecurityTokenHandler _handler = new() { MapInboundClaims = false };

    public SessaoNegocio(ConfiguracaoJwt jwt)
    {
        _jwt = jwt;
        _arquivoRevogados = Path.Combine(jwt.DiretorioPrivado, "jwt-revogados.json");
        _revogados = File.Exists(_arquivoRevogados)
            ? JsonSerializer.Deserialize<Dictionary<string, DateTime>>(File.ReadAllText(_arquivoRevogados)) ?? []
            : [];
    }

    public SessaoUsuario Abrir(PerfilUsuario perfil, string role)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, perfil.Id),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new Claim(ClaimTypes.NameIdentifier, perfil.Id),
            new Claim(ClaimTypes.Name, perfil.Name),
            new Claim(ClaimTypes.Role, role)
        };
        var token = new JwtSecurityToken(ConfiguracaoJwt.Emissor, ConfiguracaoJwt.Publico, claims,
            notBefore: DateTime.UtcNow, expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: new SigningCredentials(_jwt.Chave, SecurityAlgorithms.HmacSha256));
        return new(_handler.WriteToken(token), perfil, role);
    }

    public ClaimsPrincipal? Identificar(string header)
    {
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return null;
        try
        {
            var usuario = _handler.ValidateToken(header[7..], _jwt.ParametrosValidacao(), out _);
            return EstaRevogado(usuario) ? null : usuario;
        }
        catch (Exception ex) when (ex is SecurityTokenException or ArgumentException)
        {
            return null;
        }
    }

    public bool EstaRevogado(ClaimsPrincipal usuario)
    {
        var id = usuario.FindFirstValue(JwtRegisteredClaimNames.Jti);
        if (id is null) return true;
        lock (_cadeado) return _revogados.ContainsKey(id);
    }

    public void Encerrar(string header)
    {
        var usuario = Identificar(header);
        var id = usuario?.FindFirstValue(JwtRegisteredClaimNames.Jti);
        if (id is null) return;
        var expira = DateTimeOffset.FromUnixTimeSeconds(long.Parse(
            usuario!.FindFirstValue(JwtRegisteredClaimNames.Exp)!, System.Globalization.CultureInfo.InvariantCulture)).UtcDateTime;
        lock (_cadeado)
        {
            foreach (var antigo in _revogados.Where(p => p.Value < DateTime.UtcNow.AddMinutes(-1)).Select(p => p.Key).ToList())
                _revogados.Remove(antigo);
            _revogados[id] = expira;
            var temporario = _arquivoRevogados + ".tmp";
            File.WriteAllText(temporario, JsonSerializer.Serialize(_revogados));
            File.Move(temporario, _arquivoRevogados, overwrite: true);
        }
    }
}

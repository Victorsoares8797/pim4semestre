using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.Encodings.Web;
using Buillon.Modelos;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;

namespace Buillon.Negocio;

public sealed class SessaoNegocio(IMemoryCache cache)
{
    public const string Esquema = "Bearer";
    private const string Prefixo = "Bearer ";

    public SessaoUsuario Abrir(PerfilUsuario perfil, string role)
    {
        var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var identity = new ClaimsIdentity(
            [new(ClaimTypes.NameIdentifier, perfil.Id), new(ClaimTypes.Name, perfil.Name),
                new(ClaimTypes.Role, role)], Esquema);
        cache.Set(token, new ClaimsPrincipal(identity), TimeSpan.FromHours(8));
        return new(token, perfil, role);
    }

    internal ClaimsPrincipal? Identificar(string header) =>
        Token(header) is { } token ? cache.Get<ClaimsPrincipal>(token) : null;

    public void Encerrar(string header)
    {
        if (Token(header) is { } token) cache.Remove(token);
    }

    private static string? Token(string header) =>
        header.Length == Prefixo.Length + 64 && header.StartsWith(Prefixo, StringComparison.OrdinalIgnoreCase)
            ? header[Prefixo.Length..] : null;
}

public sealed class SessaoHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger,
    UrlEncoder encoder, SessaoNegocio sessoes) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var usuario = sessoes.Identificar(Request.Headers.Authorization.ToString());
        return Task.FromResult(usuario is null
            ? AuthenticateResult.NoResult()
            : AuthenticateResult.Success(new AuthenticationTicket(usuario, Scheme.Name)));
    }
}

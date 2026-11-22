using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.IdentityModel.Tokens;
using Xunit;

namespace Buillon.Tests;

public class JwtTests : IDisposable
{
    private readonly string _pasta = Path.Combine(Path.GetTempPath(), "buillon-jwt-teste-" + Guid.NewGuid().ToString("N"));

    [Fact]
    public void JwtPreservaIdentidadeEContinuaValidoDepoisDeReiniciar()
    {
        var sessao = new SessaoNegocio(new ConfiguracaoJwt(null, _pasta));
        var token = sessao.Abrir(new("10", "Cliente Teste", "teste@example.com", "", ""), Perfis.Cliente).Token;
        Assert.Equal(3, token.Split('.').Length);
        var reiniciada = new SessaoNegocio(new ConfiguracaoJwt(null, _pasta));
        var usuario = reiniciada.Identificar("Bearer " + token);
        Assert.NotNull(usuario);
        Assert.Equal("10", usuario.FindFirstValue(ClaimTypes.NameIdentifier));
        Assert.True(usuario.IsInRole(Perfis.Cliente));
        Assert.Equal("Cliente Teste", usuario.Identity!.Name);
    }

    [Fact]
    public void LogoutRevogaSomenteAquelaSessaoInclusiveDepoisDeReiniciar()
    {
        var sessao = new SessaoNegocio(new ConfiguracaoJwt(null, _pasta));
        var perfil = new PerfilUsuario("10", "Cliente", "teste@example.com", "", "");
        var encerrada = "Bearer " + sessao.Abrir(perfil, Perfis.Cliente).Token;
        var outra = "Bearer " + sessao.Abrir(perfil, Perfis.Cliente).Token;
        sessao.Encerrar(encerrada);
        var reiniciada = new SessaoNegocio(new ConfiguracaoJwt(null, _pasta));
        Assert.Null(reiniciada.Identificar(encerrada));
        Assert.NotNull(reiniciada.Identificar(outra));
    }

    [Fact]
    public void AlterarPerfilNoPayloadNaoPermiteForjarProprietario()
    {
        var sessao = new SessaoNegocio(new ConfiguracaoJwt(null, _pasta));
        var partes = sessao.Abrir(new("1", "Cliente", "a@example.com", "", ""), Perfis.Cliente).Token.Split('.');
        var json = Base64UrlEncoder.Decode(partes[1]).Replace("Cliente\"", "Proprietario\"");
        partes[1] = Base64UrlEncoder.Encode(json);
        Assert.Null(sessao.Identificar("Bearer " + string.Join('.', partes)));
        Assert.Null(sessao.Identificar("Bearer token-invalido"));
    }

    [Theory]
    [InlineData("expirado")]
    [InlineData("emissor")]
    [InlineData("publico")]
    [InlineData("assinatura")]
    public void RecusaTokenExpiradoOuComOrigemInvalida(string caso)
    {
        var configuracao = new ConfiguracaoJwt(null, _pasta);
        var chave = caso == "assinatura"
            ? new SymmetricSecurityKey(System.Security.Cryptography.RandomNumberGenerator.GetBytes(64)) : configuracao.Chave;
        var token = new JwtSecurityToken(caso == "emissor" ? "outro" : ConfiguracaoJwt.Emissor,
            caso == "publico" ? "outro" : ConfiguracaoJwt.Publico,
            [new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))],
            expires: caso == "expirado" ? DateTime.UtcNow.AddMinutes(-5) : DateTime.UtcNow.AddMinutes(5),
            signingCredentials: new SigningCredentials(chave, SecurityAlgorithms.HmacSha256));
        Assert.Null(new SessaoNegocio(configuracao).Identificar("Bearer " + new JwtSecurityTokenHandler().WriteToken(token)));
    }

    public void Dispose()
    {
        // Exclusivamente a pasta temporária criada por esta instância.
        if (Directory.Exists(_pasta))
        {
            foreach (var arquivo in Directory.GetFiles(_pasta)) File.Delete(arquivo);
            Directory.Delete(_pasta);
        }
    }
}

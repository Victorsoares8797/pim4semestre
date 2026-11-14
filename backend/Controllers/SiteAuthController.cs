using System.Security.Claims;
using System.Globalization;
using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Buillon.Api.Controllers;

[ApiController]
[Route("api/site/auth")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class SiteAuthController(AutenticacaoNegocio autenticacao, SessaoNegocio sessoes,
    RestauranteNegocio restaurantes) : ControllerBase
{
    private const string Cookie = "BuillonSessao";

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginDto dto, CancellationToken ct)
    {
        VerificarDocumento(dto.Role, dto.Documento);
        return Abrir(await autenticacao.ValidarLoginAsync(dto, ct), 200);
    }

    [HttpPost("registar")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Registar(RegistoUsuarioDto dto, CancellationToken ct) =>
        Abrir(await autenticacao.RegistarUsuarioAsync(dto, ct), 201);

    [HttpGet("sessao")]
    public IActionResult Sessao()
    {
        var usuario = sessoes.Identificar(SessaoAtual());
        return usuario is null ? Unauthorized() : Ok(new
        {
            name = usuario.Identity?.Name,
            role = usuario.FindFirstValue(ClaimTypes.Role)
        });
    }

    [HttpPost("sair")]
    public IActionResult Sair()
    {
        sessoes.Encerrar(SessaoAtual());
        Response.Cookies.Delete(Cookie, OpcoesCookie());
        return NoContent();
    }

    [HttpGet("estabelecimentos")]
    public async Task<IActionResult> Estabelecimentos(CancellationToken ct, int pagina = 1)
    {
        var usuario = sessoes.Identificar(SessaoAtual());
        if (usuario is null) return Unauthorized();
        if (!usuario.IsInRole(Perfis.Proprietario)) return StatusCode(403);

        var itens = await restaurantes.ListarDoProprietarioAsync(IdDaConta(usuario), pagina, ct);
        return Ok(itens.Select(item => new
        {
            item.Id, item.Name, item.Category, item.Address, item.Description, item.Fotos
        }));
    }

    [HttpPost("estabelecimentos")]
    [RequestSizeLimit(7 * 1024 * 1024)]
    public async Task<IActionResult> CadastrarEstabelecimento(CadastroEstabelecimentoSiteDto dto, CancellationToken ct)
    {
        var usuario = sessoes.Identificar(SessaoAtual());
        if (usuario is null) return Unauthorized();
        if (!usuario.IsInRole(Perfis.Proprietario)) return StatusCode(403);

        var dados = new SalvarRestauranteDto(dto.Nome, dto.Descricao, dto.Rua, dto.Numero, dto.Bairro,
            dto.Cidade, dto.Estado, dto.Cep, dto.Telefone, dto.CategoriaId, dto.Cnpj);
        var id = await restaurantes.SalvarAsync(null, IdDaConta(usuario), dados, ct, dto.Arquivo);
        return Created($"/api/restaurantes/{id}", new { id });
    }

    [HttpPost("estabelecimentos/{id:int}/fotos")]
    [RequestSizeLimit(7 * 1024 * 1024)]
    public async Task<IActionResult> AdicionarFoto(int id, FotoRestauranteDto dto, CancellationToken ct)
    {
        var usuario = sessoes.Identificar(SessaoAtual());
        if (usuario is null) return Unauthorized();
        if (!usuario.IsInRole(Perfis.Proprietario)) return StatusCode(403);

        await restaurantes.AdicionarFotoAsync(id, IdDaConta(usuario), dto, ct);
        return NoContent();
    }

    private static int IdDaConta(ClaimsPrincipal usuario) =>
        int.Parse(usuario.FindFirstValue(ClaimTypes.NameIdentifier)!, CultureInfo.InvariantCulture);

    private IActionResult Abrir(SessaoUsuario sessao, int status)
    {
        sessoes.Encerrar(SessaoAtual());
        Response.Cookies.Append(Cookie, sessao.Token, OpcoesCookie());
        return StatusCode(status, new { name = sessao.User.Name, sessao.Role });
    }

    private string SessaoAtual() => $"Bearer {Request.Cookies[Cookie]}";

    private CookieOptions OpcoesCookie() => new()
    {
        HttpOnly = true,
        Secure = Request.IsHttps,
        SameSite = SameSiteMode.Strict,
        Path = "/api/site/auth"
    };

    private static void VerificarDocumento(string? role, string? documento)
    {
        var proprietario = role == Perfis.Proprietario;
        var digitos = AutenticacaoNegocio.NormalizarDocumento(documento);
        if (digitos.Length != (proprietario ? 14 : 11) || !digitos.All(char.IsAsciiDigit))
            throw new ApiException(400, proprietario ? "Informe o CNPJ com 14 dígitos." : "Informe o CPF com 11 dígitos.");
    }
}

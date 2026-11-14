using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Buillon.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(AutenticacaoNegocio autenticacao, SessaoNegocio sessoes) : ControllerBase
{
    [HttpPost("registar")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Registar(RegistoUsuarioDto dto, CancellationToken ct) =>
        StatusCode(201, await autenticacao.RegistarUsuarioAsync(dto, ct));

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginDto dto, CancellationToken ct) =>
        Ok(await autenticacao.ValidarLoginAsync(dto, ct));

    [HttpPost("sair")]
    [Authorize]
    public IActionResult Sair()
    {
        sessoes.Encerrar(Request.Headers.Authorization.ToString());
        return NoContent();
    }
}

using System.Globalization;
using System.Security.Claims;
using Buillon.Modelos;
using Buillon.Negocio;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Buillon.Api.Controllers;

[ApiController]
[Route("api/perfil")]
[Authorize(Roles = Perfis.Cliente + "," + Perfis.Proprietario)]
public sealed class PerfilController(UsuarioRepositorio usuarios, AvaliacaoRepositorio avaliacoes) : ControllerBase
{
    private int UsuarioId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!, CultureInfo.InvariantCulture);
    private bool Proprietario => User.IsInRole(Perfis.Proprietario);

    [HttpPut]
    public Task<PerfilUsuario> Atualizar(AtualizarPerfilDto dto, CancellationToken ct)
    {
        if (dto.Avatar is not ("" or "assets/images/avatar_1.jpg" or "assets/images/avatar_2.jpg" or "assets/images/avatar_3.jpg"))
            throw new ApiException(400, "Selecione uma foto disponível.");
        return usuarios.AtualizarPerfilAsync(UsuarioId, Proprietario, RestauranteNegocio.Obrigatorio(dto.Name, "Nome", 2, 60),
            RestauranteNegocio.Opcional(dto.Bio, 160) ?? "", dto.Avatar, ct);
    }

    [HttpGet("favoritos")]
    public Task<List<string>> Favoritos(CancellationToken ct) => avaliacoes.FavoritosAsync(UsuarioId, Proprietario, ct);

    [HttpPut("favoritos/{id:int}")]
    public async Task<IActionResult> DefinirFavorito(int id, SalvarFavoritoDto dto, CancellationToken ct)
    {
        if (dto.Favorite is not { } favorito) throw new ApiException(400, "Informe o estado do favorito.");
        await avaliacoes.DefinirFavoritoAsync(UsuarioId, Proprietario, id, favorito, ct);
        return NoContent();
    }
}

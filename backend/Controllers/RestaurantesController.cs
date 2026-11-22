using System.Globalization;
using System.Security.Claims;
using Buillon.Modelos;
using Buillon.Negocio;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Buillon.Api.Controllers;

[ApiController]
[Route("api/restaurantes")]
public sealed class RestaurantesController(RestauranteNegocio negocio, IRestauranteRepositorio restaurantes,
    AvaliacaoRepositorio avaliacoes) : ControllerBase
{
    private int UsuarioId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!, CultureInfo.InvariantCulture);

    [HttpGet]
    public Task<List<RestauranteResposta>> Listar(string? cidade, string? bairro, CancellationToken ct,
        int pagina = 1, int tamanho = 10) => negocio.ListarNaAreaAsync(cidade, bairro, pagina, tamanho, ct);

    [HttpGet("{id:int}")]
    public Task<RestauranteResposta> Obter(int id, CancellationToken ct) => negocio.ObterPorIdAsync(id, ct);

    [HttpGet("meus")]
    [Authorize(Roles = Perfis.Proprietario)]
    public Task<List<RestauranteResposta>> Meus(CancellationToken ct, int pagina = 1) =>
        negocio.ListarDoProprietarioAsync(UsuarioId, pagina, ct);

    [HttpGet("imagens/{id:guid}")]
    [ResponseCache(Duration = 86400)]
    public async Task<IActionResult> Imagem(Guid id, CancellationToken ct)
    {
        var imagem = await restaurantes.ObterImagemAsync(id, ct);
        if (imagem is null) return NotFound();
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        return File(imagem.Dados, imagem.Tipo);
    }

    [HttpGet("categorias")]
    public Task<List<Categoria>> Categorias(CancellationToken ct) => restaurantes.CategoriasAsync(ct);

    [HttpGet("ranking")]
    public Task<List<PosicaoRanking>> Ranking(CancellationToken ct) => restaurantes.BuscarRankingAsync(ct);

    [HttpPost]
    [Authorize(Roles = Perfis.Proprietario)]
    public async Task<IActionResult> Cadastrar(SalvarRestauranteDto dto, CancellationToken ct)
    {
        var id = await negocio.CadastrarRestauranteAsync(dto, UsuarioId, ct);
        return CreatedAtAction(nameof(Obter), new { id }, new { id });
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Perfis.Proprietario)]
    public async Task<IActionResult> EditarPagina(int id, SalvarRestauranteDto dto, CancellationToken ct)
    {
        await negocio.EditarPaginaDoEstabelecimentoAsync(id, UsuarioId, dto, ct);
        return NoContent();
    }

    [HttpPost("{id:int}/cardapio")]
    [RequestSizeLimit(7 * 1024 * 1024)]
    [Authorize(Roles = Perfis.Proprietario)]
    public async Task<IActionResult> AdicionarItem(int id, ItemCardapioDto dto, CancellationToken ct)
    {
        await negocio.AdicionarItemCardapioAsync(id, UsuarioId, dto, ct);
        return NoContent();
    }

    [HttpPost("{id:int}/fotos")]
    [RequestSizeLimit(7 * 1024 * 1024)]
    [Authorize(Roles = Perfis.Proprietario)]
    public async Task<IActionResult> AdicionarFoto(int id, FotoRestauranteDto dto, CancellationToken ct)
    {
        await negocio.AdicionarFotoAsync(id, UsuarioId, dto, ct);
        return NoContent();
    }

    [HttpPost("{id:int}/publicacoes")]
    [Authorize(Roles = Perfis.Proprietario)]
    public async Task<IActionResult> Publicar(int id, PublicacaoDto dto, CancellationToken ct)
    {
        await negocio.PublicarAsync(id, UsuarioId, dto, ct);
        return NoContent();
    }

    [HttpGet("avaliacoes")]
    [Authorize]
    public Task<List<AvaliacaoResposta>> ListarAvaliacoes(CancellationToken ct) => avaliacoes.ListarAsync(ct);

    [HttpPut("{id:int}/avaliacao")]
    [Authorize(Roles = Perfis.Cliente)]
    public Task<AvaliacaoResposta> Avaliar(int id, SalvarAvaliacaoDto dto, CancellationToken ct) =>
        negocio.AvaliarRestauranteAsync(id, UsuarioId, dto, ct);

    [HttpDelete("avaliacoes/{id:int}")]
    [Authorize(Roles = Perfis.Cliente)]
    public async Task<IActionResult> ExcluirAvaliacao(int id, CancellationToken ct)
    {
        await avaliacoes.ExcluirAsync(id, UsuarioId, ct);
        return NoContent();
    }
}

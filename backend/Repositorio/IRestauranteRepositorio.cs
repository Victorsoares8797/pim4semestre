using Buillon.Modelos;

namespace Buillon.Repositorio;

public interface IRestauranteRepositorio
{
    Task<List<Restaurante>> ListarPorAreaAsync(string? cidade, string? bairro, int pagina, int tamanho, CancellationToken ct);
    Task<Restaurante?> ObterCompletoPorIdAsync(int id, CancellationToken ct);
    Task<Restaurante?> ObterPorProprietarioIdAsync(int proprietarioId, CancellationToken ct);
    Task<List<Restaurante>> ListarDoProprietarioAsync(int proprietarioId, int pagina, CancellationToken ct);
    Task AdicionarAsync(Restaurante restaurante, CancellationToken ct);
    Task AtualizarAsync(Restaurante restaurante, CancellationToken ct);
    Task AdicionarItemCardapioAsync(ItemCardapio item, CancellationToken ct);
    Task AdicionarFotoAsync(FotoRestaurante foto, CancellationToken ct);
    Task<int> SalvarAsync(int? id, int fornecedor, SalvarRestauranteDto dto, CancellationToken ct,
        ImagemEstabelecimento? foto = null);
    Task AdicionarItemCardapioAsync(int id, int fornecedor, ItemCardapioDto dto, ImagemEstabelecimento? imagem, CancellationToken ct);
    Task AdicionarFotoAsync(int id, int fornecedor, FotoRestauranteDto dto, ImagemEstabelecimento? imagem, CancellationToken ct);
    Task PublicarAsync(int id, int fornecedor, string comentario, CancellationToken ct);
    Task<List<Categoria>> CategoriasAsync(CancellationToken ct);
    Task<List<PosicaoRanking>> BuscarRankingAsync(CancellationToken ct);
    Task<ImagemEstabelecimento?> ObterImagemAsync(Guid id, CancellationToken ct);
}

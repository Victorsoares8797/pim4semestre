using System.Globalization;
using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.EntityFrameworkCore;

namespace Buillon.Repositorio;

public class RestauranteRepositorio(BuillonContext context) : IRestauranteRepositorio
{
    private IQueryable<Restaurante> ConsultaCompleta() => context.Restaurantes.AsNoTracking()
        .Include(r => r.Categoria).Include(r => r.Enderecos)
        .Include(r => r.Cardapio).Include(r => r.Fotos).Include(r => r.Avaliacoes)
        .Include(r => r.Publicacoes.OrderByDescending(p => p.Id).Take(50))
        .AsSplitQuery();

    public Task<List<Restaurante>> ListarPorAreaAsync(string? cidade, string? bairro,
        int pagina, int tamanho, CancellationToken ct)
    {
        var query = ConsultaCompleta();
        // ENDERECO é uma tabela separada no SQL enviado. Usa o endereço de menor ID.
        if (!string.IsNullOrWhiteSpace(cidade))
            query = query.Where(r => (r.Enderecos.OrderBy(e => e.Id).Select(e => e.Cidade).FirstOrDefault() ?? "")
                .ToLower().Contains(cidade.ToLower()));
        if (!string.IsNullOrWhiteSpace(bairro))
            query = query.Where(r => (r.Enderecos.OrderBy(e => e.Id).Select(e => e.Bairro).FirstOrDefault() ?? "")
                .ToLower().Contains(bairro.ToLower()));
        return query.OrderByDescending(r => r.Avaliacoes.Average(a => (double?)a.Nota) ?? 0)
            .ThenBy(r => r.Id).Skip((pagina - 1) * tamanho).Take(tamanho).ToListAsync(ct);
    }

    public Task<Restaurante?> ObterCompletoPorIdAsync(int id, CancellationToken ct) =>
        ConsultaCompleta().SingleOrDefaultAsync(r => r.Id == id, ct);

    public Task<Restaurante?> ObterPorProprietarioIdAsync(int proprietarioId, CancellationToken ct) =>
        ConsultaCompleta().OrderBy(r => r.Id).FirstOrDefaultAsync(r => r.ProprietarioId == proprietarioId, ct);

    public Task<List<Restaurante>> ListarDoProprietarioAsync(int proprietarioId, int pagina, CancellationToken ct) =>
        ConsultaCompleta().Where(r => r.ProprietarioId == proprietarioId).OrderBy(r => r.Id)
            .Skip((pagina - 1) * 50).Take(50).ToListAsync(ct);

    public async Task AdicionarAsync(Restaurante restaurante, CancellationToken ct)
    {
        context.Restaurantes.Add(restaurante);
        await context.SaveChangesAsync(ct);
    }

    public async Task AtualizarAsync(Restaurante restaurante, CancellationToken ct)
    {
        if (context.Entry(restaurante).State == EntityState.Detached)
            context.Restaurantes.Update(restaurante);
        await context.SaveChangesAsync(ct);
    }

    public async Task AdicionarItemCardapioAsync(ItemCardapio item, CancellationToken ct)
    {
        context.ItensCardapio.Add(item);
        await context.SaveChangesAsync(ct);
    }

    public async Task AdicionarFotoAsync(FotoRestaurante foto, CancellationToken ct)
    {
        context.FotosRestaurante.Add(foto);
        await context.SaveChangesAsync(ct);
    }

    public async Task<int> SalvarAsync(int? id, int fornecedor, SalvarRestauranteDto dto,
        CancellationToken ct, ImagemEstabelecimento? foto = null)
    {
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        if (!await context.Categorias.AnyAsync(c => c.Id == dto.CategoriaId, ct))
            throw new ApiException(400, "Categoria inválida.");
        Restaurante restaurante;
        if (id is null)
        {
            restaurante = new Restaurante(dto.Nome!, dto.Descricao ?? "", dto.Rua!, dto.Bairro ?? "",
                dto.Cidade!, dto.Telefone ?? "", fornecedor);
        }
        else
        {
            restaurante = await VerificarProprietarioAsync(id.Value, fornecedor, ct);
            await context.Entry(restaurante).Collection(r => r.Enderecos).LoadAsync(ct);
            restaurante.AtualizarPagina(dto.Nome!, dto.Descricao ?? "", dto.Rua!, dto.Bairro ?? "",
                dto.Cidade!, dto.Telefone ?? "");
        }
        restaurante.CategoriaId = dto.CategoriaId;
        restaurante.Cnpj = dto.Cnpj ?? restaurante.Cnpj;
        var endereco = restaurante.EnderecoPrincipal!;
        endereco.Numero = dto.Numero; endereco.Estado = dto.Estado; endereco.Cep = dto.Cep;
        if (id is null) await AdicionarAsync(restaurante, ct);
        else await AtualizarAsync(restaurante, ct);
        if (foto is not null)
        {
            var url = GravarImagem(restaurante.Id, foto);
            await AdicionarFotoAsync(new FotoRestaurante { RestauranteId = restaurante.Id, UrlFoto = url }, ct);
        }
        await transaction.CommitAsync(ct);
        return restaurante.Id;
    }

    public async Task AdicionarItemCardapioAsync(int id, int fornecedor, ItemCardapioDto dto,
        ImagemEstabelecimento? imagem, CancellationToken ct)
    {
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        await VerificarProprietarioAsync(id, fornecedor, ct);
        var item = new ItemCardapio
        {
            RestauranteId = id, NomePrato = dto.Nome!, Descricao = dto.Descricao ?? "",
            Preco = dto.Preco, Imagem = imagem is null ? dto.Imagem ?? "" : GravarImagem(id, imagem)
        };
        item.Validar();
        await AdicionarItemCardapioAsync(item, ct);
        await transaction.CommitAsync(ct);
    }

    public async Task AdicionarFotoAsync(int id, int fornecedor, FotoRestauranteDto dto,
        ImagemEstabelecimento? imagem, CancellationToken ct)
    {
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        await VerificarProprietarioAsync(id, fornecedor, ct);
        var foto = new FotoRestaurante
        {
            RestauranteId = id, UrlFoto = imagem is null ? dto.Url! : GravarImagem(id, imagem),
            Legenda = dto.Legenda ?? ""
        };
        foto.Validar();
        await AdicionarFotoAsync(foto, ct);
        await transaction.CommitAsync(ct);
    }

    public async Task PublicarAsync(int id, int fornecedor, string comentario, CancellationToken ct)
    {
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        await VerificarProprietarioAsync(id, fornecedor, ct);
        context.Publicacoes.Add(new PublicacaoEstabelecimento { RestauranteId = id, Comentario = comentario });
        await context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
    }

    private string GravarImagem(int id, ImagemEstabelecimento imagem)
    {
        var chave = Guid.NewGuid();
        context.Imagens.Add(new ArquivoImagem
        {
            Id = chave, RestauranteId = id, Tipo = imagem.Tipo, Dados = imagem.Dados
        });
        return $"api/restaurantes/imagens/{chave:D}";
    }

    private async Task<Restaurante> VerificarProprietarioAsync(int id, int fornecedor, CancellationToken ct)
    {
        var restaurante = await context.Restaurantes
            .FromSqlInterpolated($"SELECT * FROM buillon.estabelecimento WHERE id_estabelecimento = {id} FOR UPDATE")
            .SingleOrDefaultAsync(ct) ?? throw new ApiException(404, "Restaurante não encontrado.");
        if (restaurante.ProprietarioId != fornecedor)
            throw new ApiException(403, "Este restaurante pertence a outro fornecedor.");
        return restaurante;
    }

    public Task<List<Categoria>> CategoriasAsync(CancellationToken ct) =>
        context.Categorias.AsNoTracking().OrderBy(c => c.Nome).ToListAsync(ct);

    public async Task<ImagemEstabelecimento?> ObterImagemAsync(Guid id, CancellationToken ct)
    {
        var imagem = await context.Imagens.AsNoTracking().SingleOrDefaultAsync(i => i.Id == id, ct);
        return imagem is null ? null : new(imagem.Tipo, imagem.Dados);
    }

    public async Task<List<PosicaoRanking>> BuscarRankingAsync(CancellationToken ct)
    {
        // Equivalente PostgreSQL da SP_RANKING_ESTABELECIMENTOS original.
        var ranking = await context.Database.SqlQuery<RankingBanco>($"""
            SELECT id_estabelecimento AS "Id", nome_fantasia AS "Nome", nome_categoria AS "Categoria",
                total_avaliacoes AS "Total", media_avaliacao AS "Media", posicao AS "Posicao"
            FROM buillon.ranking_estabelecimentos() ORDER BY posicao
            """).ToListAsync(ct);
        return ranking.Select(r => new PosicaoRanking(Chave(r.Id), r.Nome, r.Categoria, r.Total, r.Media, r.Posicao)).ToList();
    }

    internal static string Chave(int id) => id.ToString(CultureInfo.InvariantCulture);
}

// Projeção de leitura da função SQL, sem criar tabela nem alterar o banco.
public sealed class RankingBanco
{
    public int Id { get; set; }
    public string Nome { get; set; } = "";
    public string Categoria { get; set; } = "";
    public long Total { get; set; }
    public decimal Media { get; set; }
    public long Posicao { get; set; }
}

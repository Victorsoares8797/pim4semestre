using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.EntityFrameworkCore;
using static Buillon.Repositorio.RestauranteRepositorio;

namespace Buillon.Repositorio;

public class AvaliacaoRepositorio(BuillonContext context)
{
    private IQueryable<Avaliacao> Consulta() => context.Avaliacoes.AsNoTracking()
        .Where(a => a.Nota != null).Include(a => a.Usuario).ThenInclude(u => u!.Perfil);

    public async Task<List<AvaliacaoResposta>> ListarAsync(CancellationToken ct) =>
        (await Consulta().OrderByDescending(a => a.DataAvaliacao ?? DateTime.MinValue)
            .ThenByDescending(a => a.Id).ToListAsync(ct)).Select(ParaResposta).ToList();

    public async Task<AvaliacaoResposta> SalvarAsync(int cliente, int restaurante, int nota, string comentario,
        int? nps, CancellationToken ct)
    {
        var avaliacao = new Avaliacao { UsuarioId = cliente, RestauranteId = restaurante, Nota = nota };
        avaliacao.Validar();
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        await VerificarRestauranteAsync(restaurante, ct);
        // Upsert atômico conserva a regra de uma avaliação por cliente/restaurante.
        // ExecuteSqlInterpolatedAsync parametriza todos os valores pelo Entity Framework.
        await context.Database.ExecuteSqlInterpolatedAsync($"""
            INSERT INTO buillon.nps AS anterior (id_cliente, id_estabelecimento, nps_geral, nps_nota, comentario)
            VALUES ({cliente}, {restaurante}, {nota}, {nps}, {comentario})
            ON CONFLICT (id_cliente, id_estabelecimento) WHERE nps_geral IS NOT NULL
            DO UPDATE SET nps_geral = excluded.nps_geral,
                nps_nota = COALESCE(excluded.nps_nota, anterior.nps_nota), comentario = excluded.comentario
            """, ct);
        var salva = await Consulta().SingleAsync(a => a.UsuarioId == cliente && a.RestauranteId == restaurante, ct);
        await transaction.CommitAsync(ct);
        return ParaResposta(salva);
    }

    public async Task ExcluirAsync(int id, int cliente, CancellationToken ct)
    {
        var removidos = await context.Avaliacoes.Where(a => a.Id == id && a.UsuarioId == cliente && a.Nota != null)
            .ExecuteDeleteAsync(ct);
        if (removidos == 0) throw new ApiException(404, "Avaliação não encontrada.");
    }

    public async Task<List<string>> FavoritosAsync(int usuario, bool proprietario, CancellationToken ct)
    {
        var ids = proprietario
            ? await context.FavoritosFornecedores.AsNoTracking().Where(f => f.FornecedorId == usuario)
                .Select(f => f.RestauranteId).ToListAsync(ct)
            : await context.FavoritosClientes.AsNoTracking().Where(f => f.UsuarioId == usuario)
                .Select(f => f.RestauranteId).ToListAsync(ct);
        return ids.Select(Chave).ToList();
    }

    public async Task DefinirFavoritoAsync(int usuario, bool proprietario, int restaurante, bool favorito, CancellationToken ct)
    {
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        if (favorito) await VerificarRestauranteAsync(restaurante, ct);
        if (proprietario)
        {
            if (favorito)
                await context.Database.ExecuteSqlInterpolatedAsync($"""
                    INSERT INTO buillon.fornecedor_favorito (id_fornecedor, id_estabelecimento)
                    VALUES ({usuario}, {restaurante}) ON CONFLICT DO NOTHING
                    """, ct);
            else
                await context.FavoritosFornecedores.Where(f => f.FornecedorId == usuario && f.RestauranteId == restaurante)
                    .ExecuteDeleteAsync(ct);
        }
        else
        {
            if (favorito)
                await context.Database.ExecuteSqlInterpolatedAsync($"""
                    INSERT INTO buillon.buillon_app_favorito (id_cliente, id_estabelecimento)
                    VALUES ({usuario}, {restaurante}) ON CONFLICT DO NOTHING
                    """, ct);
            else
                await context.FavoritosClientes.Where(f => f.UsuarioId == usuario && f.RestauranteId == restaurante)
                    .ExecuteDeleteAsync(ct);
        }
        await transaction.CommitAsync(ct);
    }

    private async Task VerificarRestauranteAsync(int id, CancellationToken ct)
    {
        // Mantém o restaurante existente durante a gravação, inclusive em concorrência.
        var restaurante = await context.Restaurantes
            .FromSqlInterpolated($"SELECT * FROM buillon.estabelecimento WHERE id_estabelecimento = {id} FOR KEY SHARE")
            .AsNoTracking().SingleOrDefaultAsync(ct);
        if (restaurante is null) throw new ApiException(404, "Restaurante não encontrado.");
    }

    private static AvaliacaoResposta ParaResposta(Avaliacao a) =>
        new(Chave(a.Id), Chave(a.RestauranteId), Chave(a.UsuarioId), a.Usuario!.Nome,
            a.Usuario.Perfil?.Avatar ?? Perfis.AvatarPadrao, a.Nota!.Value,
            a.Comentario ?? "", a.DataAvaliacao, a.NpsNota);
}

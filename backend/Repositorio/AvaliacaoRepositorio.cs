using Buillon.Modelos;
using Buillon.Negocio;
using Npgsql;
using static Buillon.Repositorio.BuillonContext;
using static Buillon.Repositorio.RestauranteRepositorio;

namespace Buillon.Repositorio;

public sealed class AvaliacaoRepositorio(BuillonContext context)
{
    private const string Avaliacoes = """
        SELECT N.ID_NPS, N.ID_ESTABELECIMENTO, N.ID_CLIENTE, C.NOME,
            COALESCE(P.AVATAR, @avatar), N.NPS_GERAL, COALESCE(N.COMENTARIO, ''),
            N.DATA_AVALIACAO, N.NPS_NOTA
        FROM buillon.NPS N INNER JOIN buillon.CLIENTE C ON C.ID_CLIENTE = N.ID_CLIENTE
        LEFT JOIN buillon.BUILLON_APP_PERFIL P ON P.ID_CLIENTE = C.ID_CLIENTE
        """;

    public Task<List<Avaliacao>> ListarAsync(CancellationToken ct) =>
        context.ConsultarAsync(Avaliacoes + """

            WHERE N.NPS_GERAL IS NOT NULL
            ORDER BY N.DATA_AVALIACAO DESC NULLS LAST, N.ID_NPS DESC
            """, AvaliacaoDaLinha, ct, Texto("@avatar", Perfis.AvatarPadrao));

    internal async Task<Avaliacao> SalvarAsync(int cliente, int restaurante, int nota, string comentario,
        int? nps, CancellationToken ct)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        await VerificarRestauranteAsync(connection, transaction, restaurante, ct);
        await using var command = Comando(connection, """
            INSERT INTO buillon.NPS AS anterior (ID_CLIENTE, ID_ESTABELECIMENTO, NPS_GERAL, NPS_NOTA, COMENTARIO)
            VALUES (@cliente, @restaurante, @nota, @nps, @comentario)
            ON CONFLICT (ID_CLIENTE, ID_ESTABELECIMENTO) WHERE NPS_GERAL IS NOT NULL
            DO UPDATE SET NPS_GERAL = excluded.NPS_GERAL,
                NPS_NOTA = COALESCE(excluded.NPS_NOTA, anterior.NPS_NOTA),
                COMENTARIO = excluded.COMENTARIO
            RETURNING ID_NPS
            """, transaction, Id("@cliente", cliente), Id("@restaurante", restaurante), Id("@nota", nota),
            Id("@nps", nps), Texto("@comentario", comentario));
        var id = (int)(await command.ExecuteScalarAsync(ct))!;

        await using var consulta = Comando(connection, Avaliacoes + "\nWHERE N.ID_NPS = @id", transaction,
            Id("@id", id), Texto("@avatar", Perfis.AvatarPadrao));
        Avaliacao avaliacao;
        await using (var reader = await consulta.ExecuteReaderAsync(ct))
        {
            if (!await reader.ReadAsync(ct)) throw new ApiException(404, "Avaliação não encontrada.");
            avaliacao = AvaliacaoDaLinha(reader);
        }
        await transaction.CommitAsync(ct);
        return avaliacao;
    }

    public async Task ExcluirAsync(int id, int cliente, CancellationToken ct)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var command = Comando(connection, """
            DELETE FROM buillon.NPS WHERE ID_NPS = @id AND ID_CLIENTE = @cliente AND NPS_GERAL IS NOT NULL
            """, null, Id("@id", id), Id("@cliente", cliente));
        if (await command.ExecuteNonQueryAsync(ct) == 0)
            throw new ApiException(404, "Avaliação não encontrada.");
    }

    private static (string Tabela, string Coluna) FavoritosDaConta(bool proprietario) =>
        proprietario ? ("FORNECEDOR_FAVORITO", "ID_FORNECEDOR") : ("BUILLON_APP_FAVORITO", "ID_CLIENTE");

    public Task<List<string>> FavoritosAsync(int usuario, bool proprietario, CancellationToken ct)
    {
        var (tabela, coluna) = FavoritosDaConta(proprietario);
        return context.ConsultarAsync($"SELECT ID_ESTABELECIMENTO FROM buillon.{tabela} WHERE {coluna} = @usuario",
            r => Chave(r.GetInt32(0)), ct, Id("@usuario", usuario));
    }

    public async Task DefinirFavoritoAsync(int usuario, bool proprietario, int restaurante, bool favorito, CancellationToken ct)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        var (tabela, coluna) = FavoritosDaConta(proprietario);
        var sql = favorito
            ? $"""
              INSERT INTO buillon.{tabela} ({coluna}, ID_ESTABELECIMENTO)
              VALUES (@usuario, @restaurante) ON CONFLICT DO NOTHING
              """
            : $"""
              DELETE FROM buillon.{tabela} WHERE {coluna} = @usuario AND ID_ESTABELECIMENTO = @restaurante
              """;
        if (favorito) await VerificarRestauranteAsync(connection, transaction, restaurante, ct);
        await using var command = Comando(connection, sql, transaction, Id("@usuario", usuario),
            Id("@restaurante", restaurante));
        await command.ExecuteNonQueryAsync(ct);
        await transaction.CommitAsync(ct);
    }

    private static async Task VerificarRestauranteAsync(NpgsqlConnection connection, NpgsqlTransaction transaction,
        int restaurante, CancellationToken ct)
    {
        await using var command = Comando(connection, """
            SELECT 1 FROM buillon.ESTABELECIMENTO WHERE ID_ESTABELECIMENTO = @id FOR KEY SHARE
            """, transaction, Id("@id", restaurante));
        if (await command.ExecuteScalarAsync(ct) is null)
            throw new ApiException(404, "Restaurante não encontrado.");
    }

    private static Avaliacao AvaliacaoDaLinha(NpgsqlDataReader r) =>
        new(Chave(r.GetInt32(0)), Chave(r.GetInt32(1)), Chave(r.GetInt32(2)), r.GetString(3),
            r.GetString(4), r.GetInt32(5), r.GetString(6),
            r.IsDBNull(7) ? null : r.GetDateTime(7),
            r.IsDBNull(8) ? null : r.GetInt32(8));
}

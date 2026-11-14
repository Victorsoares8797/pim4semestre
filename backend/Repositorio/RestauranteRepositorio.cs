using System.Globalization;
using System.Text.Json;
using Buillon.Modelos;
using Buillon.Negocio;
using Npgsql;
using NpgsqlTypes;
using static Buillon.Repositorio.BuillonContext;

namespace Buillon.Repositorio;

public sealed class RestauranteRepositorio(BuillonContext context)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private const string InserirFoto = """
        INSERT INTO buillon.BUILLON_APP_FOTO (ID_ESTABELECIMENTO, URL, LEGENDA) VALUES (@id, @imagem, @legenda)
        """;

    public Task<List<Restaurante>> ListarPorAreaAsync(string? cidade, string? bairro, int? id,
        int pagina, int tamanho, CancellationToken ct, int? fornecedor = null) =>
        context.ConsultarAsync("""
            SELECT E.ID_ESTABELECIMENTO, E.NOME_FANTASIA, C.NOME_CATEGORIA, COALESCE(A.BAIRRO, ''),
                CONCAT_WS(', ', NULLIF(CONCAT_WS(' ', NULLIF(A.RUA, ''), NULLIF(A.NUMERO, '')), ''),
                    NULLIF(A.BAIRRO, ''), NULLIF(A.CIDADE, ''), NULLIF(A.ESTADO, ''), NULLIF(A.CEP, '')),
                COALESCE(E.DESCRICAO, ''), COALESCE(F.URL, ''),
                (SELECT json_agg(json_build_object('name', P.NOME, 'description', P.DESCRICAO,
                    'image', P.IMAGEM, 'price', P.PRECO) ORDER BY P.ID_ITEM)::text
                 FROM buillon.BUILLON_APP_CARDAPIO P WHERE P.ID_ESTABELECIMENTO = E.ID_ESTABELECIMENTO),
                CASE WHEN @id IS NOT NULL OR @fornecedor IS NOT NULL THEN
                    (SELECT json_agg(json_build_object('url', G.URL, 'legenda', G.LEGENDA) ORDER BY G.ID_FOTO)::text
                     FROM buillon.BUILLON_APP_FOTO G WHERE G.ID_ESTABELECIMENTO = E.ID_ESTABELECIMENTO)
                END,
                CASE WHEN @id IS NOT NULL OR @fornecedor IS NOT NULL THEN
                    (SELECT json_agg(json_build_object('id', U.ID, 'comentario', U.COMENTARIO,
                        'criadoEm', U.CRIADO_EM) ORDER BY U.ID DESC)::text
                     FROM (SELECT ID, COMENTARIO, CRIADO_EM FROM buillon.ESTABELECIMENTO_PUBLICACAO
                           WHERE ID_ESTABELECIMENTO = E.ID_ESTABELECIMENTO ORDER BY ID DESC LIMIT 50) U)
                END,
                E.ID_CATEGORIA, COALESCE(E.CNPJ, ''), COALESCE(A.RUA, ''), COALESCE(A.NUMERO, ''),
                COALESCE(A.CIDADE, ''), COALESCE(A.ESTADO, ''), COALESCE(A.CEP, ''), COALESCE(E.TELEFONE, ''),
                COALESCE(E.FAIXA_PRECO, ''), COALESCE(E.HORARIO, ''), E.CHAVE_EXEMPLO IS NOT NULL
            FROM buillon.ESTABELECIMENTO E
            INNER JOIN buillon.CATEGORIA C ON C.ID_CATEGORIA = E.ID_CATEGORIA
            LEFT JOIN LATERAL (
                SELECT RUA, NUMERO, BAIRRO, CIDADE, ESTADO, CEP FROM buillon.ENDERECO A
                WHERE A.ID_ESTABELECIMENTO = E.ID_ESTABELECIMENTO ORDER BY A.ID_ENDERECO LIMIT 1
            ) A ON TRUE
            LEFT JOIN LATERAL (
                SELECT URL FROM buillon.BUILLON_APP_FOTO F
                WHERE F.ID_ESTABELECIMENTO = E.ID_ESTABELECIMENTO ORDER BY F.ID_FOTO LIMIT 1
            ) F ON TRUE
            WHERE (@id IS NULL OR E.ID_ESTABELECIMENTO = @id)
              AND (@fornecedor IS NULL OR E.ID_FORNECEDOR = @fornecedor)
              AND (@cidade IS NULL OR strpos(lower(A.CIDADE), lower(@cidade)) > 0)
              AND (@bairro IS NULL OR strpos(lower(A.BAIRRO), lower(@bairro)) > 0)
            ORDER BY E.ID_ESTABELECIMENTO
            LIMIT @tamanho OFFSET @offset
            """, r => new Restaurante(
                Chave(r.GetInt32(0)), r.GetString(1), r.GetString(2), r.GetString(3), r.GetString(4),
                r.GetString(5), r.GetString(6), r.GetString(18), r.GetString(19),
                LerLista<ItemCardapio>(r, 7), LerLista<FotoRestaurante>(r, 8), LerLista<PublicacaoEstabelecimento>(r, 9),
                fornecedor is null ? null : new DadosEstabelecimento(r.GetInt32(10), r.GetString(11), r.GetString(12),
                    r.GetString(13), r.GetString(3), r.GetString(14), r.GetString(15), r.GetString(16), r.GetString(17)),
                r.GetBoolean(20)),
            ct, Id("@id", id), Id("@fornecedor", fornecedor), Texto("@cidade", cidade), Texto("@bairro", bairro),
            Id("@offset", (pagina - 1) * tamanho), Id("@tamanho", tamanho));

    private static List<T> LerLista<T>(NpgsqlDataReader reader, int ordinal) =>
        reader.IsDBNull(ordinal) ? [] : JsonSerializer.Deserialize<List<T>>(reader.GetString(ordinal), Json) ?? [];

    public async Task<ImagemEstabelecimento?> ObterImagemAsync(Guid id, CancellationToken ct) =>
        (await context.ConsultarAsync("""
            SELECT TIPO, DADOS FROM buillon.ESTABELECIMENTO_IMAGEM WHERE ID = @id
            """, r => new ImagemEstabelecimento(r.GetString(0), r.GetFieldValue<byte[]>(1)), ct,
            new NpgsqlParameter("@id", NpgsqlDbType.Uuid) { Value = id })).FirstOrDefault();

    public Task<List<PosicaoRanking>> BuscarRankingAsync(CancellationToken ct) =>
        context.ConsultarAsync("SELECT * FROM buillon.ranking_estabelecimentos() ORDER BY posicao", r => new PosicaoRanking(
            Chave(r.GetInt32(0)), r.GetString(1), r.GetString(2), r.GetInt64(3), r.GetDecimal(4), r.GetInt64(5)), ct);

    public Task<List<Categoria>> CategoriasAsync(CancellationToken ct) =>
        context.ConsultarAsync("SELECT ID_CATEGORIA, NOME_CATEGORIA FROM buillon.CATEGORIA ORDER BY NOME_CATEGORIA",
            r => new Categoria(r.GetInt32(0), r.GetString(1)), ct);

    internal async Task<int> SalvarAsync(int? id, int fornecedor, SalvarRestauranteDto dto, CancellationToken ct,
        ImagemEstabelecimento? foto = null)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        var sql = id is null
            ? """
              INSERT INTO buillon.ESTABELECIMENTO (ID_FORNECEDOR, ID_CATEGORIA, NOME_FANTASIA, CNPJ, TELEFONE, DESCRICAO)
              SELECT @fornecedor, ID_CATEGORIA, @nome, @cnpj, @telefone, @descricao
              FROM buillon.CATEGORIA WHERE ID_CATEGORIA = @categoria
              RETURNING ID_ESTABELECIMENTO
              """
            : """
              UPDATE buillon.ESTABELECIMENTO E SET ID_CATEGORIA = C.ID_CATEGORIA, NOME_FANTASIA = @nome,
                CNPJ = COALESCE(@cnpj, E.CNPJ), TELEFONE = @telefone, DESCRICAO = @descricao
              FROM buillon.CATEGORIA C
              WHERE E.ID_ESTABELECIMENTO = @id AND E.ID_FORNECEDOR = @fornecedor AND C.ID_CATEGORIA = @categoria
              RETURNING E.ID_ESTABELECIMENTO
              """;
        if (id is not null)
            await VerificarProprietarioAsync(connection, transaction, id.Value, fornecedor, ct);

        await using var restaurante = Comando(connection, sql, transaction,
            Id("@id", id), Id("@fornecedor", fornecedor), Id("@categoria", dto.CategoriaId),
            Texto("@nome", dto.Nome), Texto("@cnpj", dto.Cnpj),
            Texto("@telefone", dto.Telefone), Texto("@descricao", dto.Descricao));
        var idSalvo = (await restaurante.ExecuteScalarAsync(ct) as int?)
            ?? throw new ApiException(400, "Categoria inválida.");

        await using var endereco = Comando(connection, """
            WITH atualizado AS (
                UPDATE buillon.ENDERECO SET RUA = @rua, NUMERO = @numero, BAIRRO = @bairro, CIDADE = @cidade,
                    ESTADO = @estado, CEP = @cep
                WHERE ID_ENDERECO = (SELECT MIN(ID_ENDERECO) FROM buillon.ENDERECO WHERE ID_ESTABELECIMENTO = @id)
                RETURNING ID_ENDERECO
            )
            INSERT INTO buillon.ENDERECO (ID_ESTABELECIMENTO, RUA, NUMERO, BAIRRO, CIDADE, ESTADO, CEP)
            SELECT @id, @rua, @numero, @bairro, @cidade, @estado, @cep
            WHERE NOT EXISTS (SELECT 1 FROM atualizado)
            """, transaction, Id("@id", idSalvo), Texto("@rua", dto.Rua),
            Texto("@numero", dto.Numero), Texto("@bairro", dto.Bairro),
            Texto("@cidade", dto.Cidade), Texto("@estado", dto.Estado), Texto("@cep", dto.Cep));
        await endereco.ExecuteNonQueryAsync(ct);
        if (foto is not null)
        {
            var url = await GravarImagemAsync(connection, transaction, idSalvo, foto, ct);
            await using var capa = Comando(connection, InserirFoto, transaction,
                Id("@id", idSalvo), Texto("@imagem", url), Texto("@legenda", ""));
            await capa.ExecuteNonQueryAsync(ct);
        }
        await transaction.CommitAsync(ct);
        return idSalvo;
    }

    internal Task AdicionarItemCardapioAsync(int id, int fornecedor, ItemCardapioDto dto,
        ImagemEstabelecimento? imagem, CancellationToken ct) =>
        GravarComplementoAsync(id, fornecedor, imagem, dto.Imagem, """
            INSERT INTO buillon.BUILLON_APP_CARDAPIO (ID_ESTABELECIMENTO, NOME, DESCRICAO, IMAGEM, PRECO)
            VALUES (@id, @nome, @descricao, @imagem, @preco)
            """, ct, Texto("@nome", dto.Nome), Texto("@descricao", dto.Descricao),
            new NpgsqlParameter("@preco", NpgsqlDbType.Numeric) { Value = dto.Preco });

    internal Task AdicionarFotoAsync(int id, int fornecedor, FotoRestauranteDto dto,
        ImagemEstabelecimento? imagem, CancellationToken ct) =>
        GravarComplementoAsync(id, fornecedor, imagem, dto.Url, InserirFoto, ct, Texto("@legenda", dto.Legenda));

    internal Task PublicarAsync(int id, int fornecedor, string comentario, CancellationToken ct) =>
        GravarComplementoAsync(id, fornecedor, null, null, """
            INSERT INTO buillon.ESTABELECIMENTO_PUBLICACAO (ID_ESTABELECIMENTO, COMENTARIO) VALUES (@id, @comentario)
            """, ct, Texto("@comentario", comentario));

    private async Task GravarComplementoAsync(int id, int fornecedor, ImagemEstabelecimento? imagem,
        string? url, string sql, CancellationToken ct,
        params NpgsqlParameter[] values)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        await VerificarProprietarioAsync(connection, transaction, id, fornecedor, ct);
        if (imagem is not null)
            url = await GravarImagemAsync(connection, transaction, id, imagem, ct);
        var parametros = url is null ? values : [Texto("@imagem", url), .. values];
        await using var command = Comando(connection, sql, transaction, [Id("@id", id), .. parametros]);
        await command.ExecuteNonQueryAsync(ct);
        await transaction.CommitAsync(ct);
    }

    private static async Task<string> GravarImagemAsync(NpgsqlConnection connection, NpgsqlTransaction transaction,
        int id, ImagemEstabelecimento imagem, CancellationToken ct)
    {
        var chave = Guid.NewGuid();
        await using var arquivo = Comando(connection, """
            INSERT INTO buillon.ESTABELECIMENTO_IMAGEM (ID, ID_ESTABELECIMENTO, TIPO, DADOS)
            VALUES (@chave, @id, @tipo, @dados)
            """, transaction, new NpgsqlParameter("@chave", NpgsqlDbType.Uuid) { Value = chave },
            Id("@id", id), Texto("@tipo", imagem.Tipo),
            new NpgsqlParameter("@dados", NpgsqlDbType.Bytea) { Value = imagem.Dados });
        await arquivo.ExecuteNonQueryAsync(ct);
        return $"api/restaurantes/imagens/{chave:D}";
    }

    private static async Task VerificarProprietarioAsync(NpgsqlConnection connection, NpgsqlTransaction transaction,
        int id, int fornecedor, CancellationToken ct)
    {
        await using var command = Comando(connection, """
            SELECT ID_FORNECEDOR FROM buillon.ESTABELECIMENTO WHERE ID_ESTABELECIMENTO = @id FOR UPDATE
            """, transaction, Id("@id", id));
        var dono = await command.ExecuteScalarAsync(ct) as int?;
        if (dono is null) throw new ApiException(404, "Restaurante não encontrado.");
        if (dono != fornecedor) throw new ApiException(403, "Este restaurante pertence a outro fornecedor.");
    }

    internal static string Chave(int id) => id.ToString(CultureInfo.InvariantCulture);
}

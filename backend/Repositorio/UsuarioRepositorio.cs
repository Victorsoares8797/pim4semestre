using System.Globalization;
using Buillon.Modelos;
using Buillon.Negocio;
using static Buillon.Repositorio.BuillonContext;

namespace Buillon.Repositorio;

public sealed class UsuarioRepositorio(BuillonContext context)
{
    internal async Task<(PerfilUsuario Perfil, string? Senha)?> ObterPorEmailAsync(
        string email, string role, string? documento, CancellationToken ct)
    {
        var sql = role == Perfis.Proprietario
            ? """
              SELECT F.ID_FORNECEDOR, F.NOME_RESPONSAVEL, F.EMAIL, F.SENHA, P.AVATAR, P.BIO
              FROM buillon.FORNECEDOR F LEFT JOIN buillon.FORNECEDOR_PERFIL P ON P.ID_FORNECEDOR = F.ID_FORNECEDOR
              WHERE lower(btrim(F.EMAIL)) = @email
                  AND (@documento IS NULL OR translate(F.DOCUMENTO, './- ', '') = @documento)
              """
            : """
              SELECT C.ID_CLIENTE, C.NOME, C.EMAIL, C.SENHA, P.AVATAR, P.BIO
              FROM buillon.CLIENTE C LEFT JOIN buillon.BUILLON_APP_PERFIL P ON P.ID_CLIENTE = C.ID_CLIENTE
              WHERE lower(btrim(C.EMAIL)) = @email
                  AND (@documento IS NULL OR translate(C.CPF, './- ', '') = @documento)
              """;
        var rows = await context.ConsultarAsync(sql, r =>
            (Perfil(r.GetInt32(0), r.GetString(1), r.GetString(2),
                r.IsDBNull(4) ? Perfis.AvatarPadrao : r.GetString(4), r.IsDBNull(5) ? "" : r.GetString(5)),
                r.IsDBNull(3) ? null : r.GetString(3)), ct, Texto("@email", email), Texto("@documento", documento));
        return rows.Count == 1 ? rows[0] : null;
    }

    internal async Task<PerfilUsuario> AdicionarAsync(string nome, string email, string senhaHash,
        string documento, string role, CancellationToken ct)
    {
        var insert = role == Perfis.Proprietario
            ? """
              INSERT INTO buillon.FORNECEDOR (NOME_RESPONSAVEL, DOCUMENTO, EMAIL, SENHA)
              VALUES (@nome, @documento, @email, @senha) ON CONFLICT DO NOTHING RETURNING ID_FORNECEDOR
              """
            : """
              INSERT INTO buillon.CLIENTE (NOME, CPF, EMAIL, SENHA)
              VALUES (@nome, @documento, @email, @senha) ON CONFLICT DO NOTHING RETURNING ID_CLIENTE
              """;

        await using var connection = await context.ConectarAsync(ct);
        await using var command = Comando(connection, insert, null, Texto("@nome", nome),
            Texto("@email", email), Texto("@documento", documento), Texto("@senha", senhaHash));
        if (await command.ExecuteScalarAsync(ct) is not int id)
            throw new ApiException(409, "Já existe uma conta com este e-mail ou documento.");
        return Perfil(id, nome, email, Perfis.AvatarPadrao, "");
    }

    internal async Task<PerfilUsuario> AtualizarPerfilAsync(int id, bool proprietario, string nome, string bio, string avatar,
        CancellationToken ct)
    {
        await using var connection = await context.ConectarAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        var atualizarNome = proprietario
            ? "UPDATE buillon.FORNECEDOR SET NOME_RESPONSAVEL = @nome WHERE ID_FORNECEDOR = @id RETURNING EMAIL"
            : """
            UPDATE buillon.CLIENTE SET NOME = @nome WHERE ID_CLIENTE = @id RETURNING EMAIL
            """;
        await using var conta = Comando(connection, atualizarNome, transaction, Id("@id", id), Texto("@nome", nome));
        var email = await conta.ExecuteScalarAsync(ct) as string
            ?? throw new ApiException(404, "Conta não encontrada.");

        var atualizarPerfil = proprietario
            ? """
              INSERT INTO buillon.FORNECEDOR_PERFIL (ID_FORNECEDOR, BIO, AVATAR) VALUES (@id, @bio, @avatar)
              ON CONFLICT (ID_FORNECEDOR) DO UPDATE SET BIO = excluded.BIO, AVATAR = excluded.AVATAR
              """
            : """
            INSERT INTO buillon.BUILLON_APP_PERFIL (ID_CLIENTE, BIO, AVATAR) VALUES (@id, @bio, @avatar)
            ON CONFLICT (ID_CLIENTE) DO UPDATE SET BIO = excluded.BIO, AVATAR = excluded.AVATAR
            """;
        await using var perfil = Comando(connection, atualizarPerfil, transaction,
            Id("@id", id), Texto("@bio", bio), Texto("@avatar", avatar));
        await perfil.ExecuteNonQueryAsync(ct);
        await transaction.CommitAsync(ct);
        return Perfil(id, nome, email, avatar, bio);
    }

    private static PerfilUsuario Perfil(int id, string nome, string email, string avatar, string bio) =>
        new(id.ToString(CultureInfo.InvariantCulture), nome, email, avatar, bio);
}

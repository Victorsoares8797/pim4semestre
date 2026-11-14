using Buillon.Negocio;
using Npgsql;
using NpgsqlTypes;

namespace Buillon.Repositorio;

public sealed class BuillonContext(IConfiguration configuration) : IAsyncDisposable
{
    private readonly Lazy<NpgsqlDataSource> _dataSource = new(() =>
    {
        var connectionString = configuration.GetConnectionString("Supabase");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new ApiException(503, "Configure ConnectionStrings:Supabase no servidor.");

        try
        {
            return NpgsqlDataSource.Create(connectionString);
        }
        catch (ArgumentException)
        {
            throw new ApiException(503, "A configuração de conexão do Supabase é inválida.");
        }
    });

    public ValueTask<NpgsqlConnection> ConectarAsync(CancellationToken ct) =>
        _dataSource.Value.OpenConnectionAsync(ct);

    public ValueTask DisposeAsync() =>
        _dataSource.IsValueCreated ? _dataSource.Value.DisposeAsync() : ValueTask.CompletedTask;

    internal static NpgsqlCommand Comando(NpgsqlConnection connection, string sql, NpgsqlTransaction? transaction = null,
        params NpgsqlParameter[] parameters)
    {
        var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddRange(parameters);
        return command;
    }

    internal static NpgsqlParameter Id(string name, int? value) =>
        new(name, NpgsqlDbType.Integer) { Value = (object?)value ?? DBNull.Value };

    internal static NpgsqlParameter Texto(string name, string? value) =>
        new(name, NpgsqlDbType.Text) { Value = (object?)value ?? DBNull.Value };

    internal async Task<List<T>> ConsultarAsync<T>(string sql, Func<NpgsqlDataReader, T> map, CancellationToken ct,
        params NpgsqlParameter[] parameters)
    {
        await using var connection = await ConectarAsync(ct);
        await using var command = Comando(connection, sql, null, parameters);
        await using var reader = await command.ExecuteReaderAsync(ct);
        var rows = new List<T>();
        while (await reader.ReadAsync(ct)) rows.Add(map(reader));
        return rows;
    }
}

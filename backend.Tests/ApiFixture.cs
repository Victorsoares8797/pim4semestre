using Buillon.Negocio;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Npgsql;
using Xunit;

namespace Buillon.Tests;

public sealed class PostgresFactAttribute : FactAttribute
{
    public PostgresFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("BUILLON_TEST_ADMIN")))
            Skip = "Defina BUILLON_TEST_ADMIN apontando para PostgreSQL local para executar a integração.";
    }
}

public sealed class ApiFixture : IAsyncLifetime
{
    private string? _admin;
    private string? _conexao;
    private readonly string _banco = "buillon_test_" + Guid.NewGuid().ToString("N");
    private readonly string _pastaJwt = Path.Combine(Path.GetTempPath(), "buillon-api-teste-" + Guid.NewGuid().ToString("N"));
    public WebApplicationFactory<Program> App { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        _admin = Environment.GetEnvironmentVariable("BUILLON_TEST_ADMIN");
        if (string.IsNullOrWhiteSpace(_admin)) return;
        var builder = new NpgsqlConnectionStringBuilder(_admin);
        if (builder.Host is not ("127.0.0.1" or "localhost" or "::1"))
            throw new InvalidOperationException("Os testes só podem criar bancos em PostgreSQL local.");
        await using (var admin = new NpgsqlConnection(_admin))
        {
            await admin.OpenAsync();
            await new NpgsqlCommand($"""CREATE DATABASE "{_banco}" """, admin).ExecuteNonQueryAsync();
        }
        builder.Database = _banco;
        _conexao = builder.ConnectionString;
        var raiz = EncontrarRaiz();
        await using (var conexao = new NpgsqlConnection(_conexao))
        {
            await conexao.OpenAsync();
            foreach (var script in Directory.GetFiles(Path.Combine(raiz, "supabase", "migrations"), "*.sql").Order())
                await new NpgsqlCommand(await File.ReadAllTextAsync(script), conexao).ExecuteNonQueryAsync();
        }
        var jwt = new ConfiguracaoJwt(null, _pastaJwt);
        App = new WebApplicationFactory<Program>().WithWebHostBuilder(web =>
        {
            web.UseEnvironment("Development");
            web.ConfigureServices(services =>
            {
                services.RemoveAll<BuillonContext>();
                services.RemoveAll<DbContextOptions<BuillonContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<BuillonContext>>();
                services.AddDbContext<BuillonContext>(options => options.UseNpgsql(_conexao));
                services.RemoveAll<ConfiguracaoJwt>();
                services.AddSingleton(jwt);
                services.PostConfigure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme,
                    options => options.TokenValidationParameters = jwt.ParametrosValidacao());
            });
        });
    }

    public async Task DisposeAsync()
    {
        if (App is not null) await App.DisposeAsync();
        if (_conexao is not null && _admin is not null)
        {
            NpgsqlConnection.ClearAllPools();
            await using var admin = new NpgsqlConnection(_admin);
            await admin.OpenAsync();
            // Nome gerado por esta fixture, em servidor local já validado.
            await new NpgsqlCommand($"""DROP DATABASE "{_banco}" WITH (FORCE)""", admin).ExecuteNonQueryAsync();
        }
        if (Directory.Exists(_pastaJwt))
        {
            foreach (var arquivo in Directory.GetFiles(_pastaJwt)) File.Delete(arquivo);
            Directory.Delete(_pastaJwt);
        }
    }

    public static string EncontrarRaiz()
    {
        var pasta = new DirectoryInfo(AppContext.BaseDirectory);
        while (pasta is not null && !File.Exists(Path.Combine(pasta.FullName, "database", "scriptPIM.sql")))
            pasta = pasta.Parent;
        return pasta?.FullName ?? throw new InvalidOperationException("Raiz do projeto não encontrada.");
    }
}

using System.Threading.RateLimiting;
using Buillon.Negocio;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.FileProviders;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true).AddEnvironmentVariables();
builder.Services.AddSingleton<BuillonContext>();
builder.Services.AddScoped<UsuarioRepositorio>();
builder.Services.AddScoped<RestauranteRepositorio>();
builder.Services.AddScoped<AvaliacaoRepositorio>();
builder.Services.AddScoped<AutenticacaoNegocio>();
builder.Services.AddScoped<RestauranteNegocio>();
builder.Services.AddSingleton<IPasswordHasher<string>, PasswordHasher<string>>();
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<SessaoNegocio>();
builder.Services.AddAuthentication(SessaoNegocio.Esquema)
    .AddScheme<AuthenticationSchemeOptions, SessaoHandler>(SessaoNegocio.Esquema, null);
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = 429;
    options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "local",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1) }));
});
var origens = (builder.Configuration["Buillon:OrigensWeb"] ?? "http://localhost:5173,http://127.0.0.1:5173")
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.WithOrigins(origens).AllowAnyHeader().AllowAnyMethod()));
builder.Services.AddControllers();

var app = builder.Build();
app.UseExceptionHandler(handler => handler.Run(async context =>
{
    var error = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>()?.Error;
    var (status, message) = error switch
    {
        ApiException api => (api.Status, api.Message),
        PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } => (409, "Já existe um registro com esses dados."),
        PostgresException { SqlState: PostgresErrorCodes.ForeignKeyViolation } => (409, "O registro relacionado não está disponível."),
        NpgsqlException => (503, "O banco BUILLON está indisponível. Confira a conexão com o Supabase."),
        _ => (500, "Não foi possível concluir. Tente novamente.")
    };
    context.Response.StatusCode = status;
    await context.Response.WriteAsJsonAsync(new { message });
}));

var arquivosWeb = app.Environment.WebRootFileProvider;
if (!arquivosWeb.GetFileInfo("site.html").Exists)
{
    var site = Path.GetFullPath("../site-pim3", app.Environment.ContentRootPath);
    if (File.Exists(Path.Combine(site, "site.html")))
        arquivosWeb = new PhysicalFileProvider(site);
}
if (arquivosWeb.GetFileInfo("site.html").Exists)
{
    var arquivosPadrao = new DefaultFilesOptions { FileProvider = arquivosWeb };
    arquivosPadrao.DefaultFileNames.Clear();
    arquivosPadrao.DefaultFileNames.Add("site.html");
    app.UseDefaultFiles(arquivosPadrao);
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = arquivosWeb,
        OnPrepareResponse = file => file.Context.Response.Headers.CacheControl = "no-cache"
    });

    // Remove registros de service worker deixados pela versão Flutter servida neste endereço.
    app.MapGet("/flutter_service_worker.js", () => Results.Text("""
        self.addEventListener('install', () => self.skipWaiting());
        self.addEventListener('activate', event => event.waitUntil(self.registration.unregister()));
        """, "application/javascript"));
}
app.UseCors();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/api/health", async (BuillonContext database, CancellationToken ct) =>
{
    await using var connection = await database.ConectarAsync(ct);
    await using var command = connection.CreateCommand();
    command.CommandText = """
        SELECT count(*) = 14 AND to_regprocedure('buillon.ranking_estabelecimentos()') IS NOT NULL
            AND EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'buillon' AND table_name = 'estabelecimento' AND column_name = 'chave_exemplo')
        FROM information_schema.tables
        WHERE table_schema = 'buillon' AND table_type = 'BASE TABLE'
            AND table_name IN ('cliente', 'fornecedor', 'estabelecimento', 'endereco', 'categoria', 'nps',
                'buillon_app_perfil', 'buillon_app_favorito', 'buillon_app_cardapio', 'buillon_app_foto',
                'estabelecimento_imagem', 'estabelecimento_publicacao', 'fornecedor_perfil', 'fornecedor_favorito')
        """;
    if (await command.ExecuteScalarAsync(ct) is not true)
        throw new ApiException(503, "Aplique a migração do Buillon no Supabase.");
    return Results.Ok(new { status = "ok" });
});
app.Run();

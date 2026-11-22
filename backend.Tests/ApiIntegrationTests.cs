using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text.Json.Nodes;
using Buillon.Modelos;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Buillon.Tests;

public class ApiIntegrationTests(ApiFixture fixture) : IClassFixture<ApiFixture>
{
    private static readonly string Foto = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=";

    [Fact]
    public void SqlOriginalContinuaIdenticoAoArquivoEnviado()
    {
        var arquivo = Path.Combine(ApiFixture.EncontrarRaiz(), "database", "scriptPIM.sql");
        Assert.Equal("9194EC6E4F3D0A2020CB741816E9DC1D8516A8D3AD8D03E6799659271AF57778",
            Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(arquivo))));
    }

    [PostgresFact]
    public async Task FluxoCompletoMantemContratosPermissoesEPersistencia()
    {
        using var publico = fixture.App.CreateClient();
        await Json(publico.GetAsync("/api/health"), HttpStatusCode.OK);
        await Json(publico.GetAsync("/openapi/v1.json"), HttpStatusCode.OK);
        var catalogo = await Json(publico.GetAsync("/api/restaurantes?tamanho=50"), HttpStatusCode.OK);
        Assert.Equal(12, catalogo!.AsArray().Count);
        Assert.All(catalogo.AsArray(), r => Assert.True(r!["isExample"]!.GetValue<bool>()));
        var categorias = await Json(publico.GetAsync("/api/restaurantes/categorias"), HttpStatusCode.OK);
        int categoria = categorias![0]!["id"]!.GetValue<int>();

        using var cliente = await Cadastrar("cliente", "12345678901", false);
        using var outroCliente = await Cadastrar("outrocliente", "12345678902", false);
        using var dono = await Cadastrar("dono", "12345678000190", true);
        using var concorrente = await Cadastrar("concorrente", "12345678000191", true);
        var dados = new
        {
            nome = "Restaurante do teste", descricao = "Cozinha de teste", rua = "Rua Teste", numero = "10",
            bairro = "Centro", cidade = "São Paulo", estado = "SP", cep = "01001000",
            telefone = "1133333333", categoriaId = categoria, cnpj = "12345678000190"
        };
        var criado = await Json(dono.PostAsJsonAsync("/api/restaurantes", dados), HttpStatusCode.Created);
        var id = criado!["id"]!.GetValue<int>();
        var caminho = "/api/restaurantes/" + id;
        await Status(cliente.PostAsJsonAsync("/api/restaurantes", dados), HttpStatusCode.Forbidden);
        await Status(concorrente.PutAsJsonAsync(caminho, dados), HttpStatusCode.Forbidden);
        await Status(dono.PutAsJsonAsync(caminho, dados with { nome = "Restaurante editado" }), HttpStatusCode.NoContent);
        var meus = await Json(dono.GetAsync("/api/restaurantes/meus"), HttpStatusCode.OK);
        Assert.Equal("Restaurante editado", meus![0]!["name"]!.GetValue<string>());
        Assert.Equal("01001000", meus[0]!["dados"]!["cep"]!.GetValue<string>());

        await Status(dono.PostAsJsonAsync(caminho + "/fotos", new { arquivo = Foto, legenda = "Capa do teste" }), HttpStatusCode.NoContent);
        await Status(dono.PostAsJsonAsync(caminho + "/cardapio",
            new { nome = "Prato do teste", descricao = "Descrição", preco = 25.50, arquivo = Foto }), HttpStatusCode.NoContent);
        await Status(dono.PostAsJsonAsync(caminho + "/publicacoes", new { comentario = "Publicação de teste" }), HttpStatusCode.NoContent);
        await Status(dono.PostAsJsonAsync(caminho + "/cardapio",
            new { nome = "Inválido", preco = -1 }), HttpStatusCode.BadRequest);
        await Status(concorrente.PostAsJsonAsync(caminho + "/fotos",
            new { arquivo = Foto, legenda = "Indevida" }), HttpStatusCode.Forbidden);
        var detalhe = await Json(publico.GetAsync(caminho), HttpStatusCode.OK);
        Assert.Equal(25.50m, detalhe!["dishes"]![0]!["price"]!.GetValue<decimal>());
        Assert.Single(detalhe["publicacoes"]!.AsArray());
        var urlFoto = detalhe["fotos"]![0]!["url"]!.GetValue<string>();
        using (var foto = await publico.GetAsync("/" + urlFoto))
        {
            Assert.Equal(HttpStatusCode.OK, foto.StatusCode);
            Assert.Equal("image/png", foto.Content.Headers.ContentType!.MediaType);
            Assert.Equal(Convert.FromBase64String(Foto), await foto.Content.ReadAsByteArrayAsync());
        }

        await Status(dono.PutAsJsonAsync(caminho + "/avaliacao",
            new { rating = 5, comment = "Tentativa do proprietário" }), HttpStatusCode.Forbidden);
        var primeira = await Json(cliente.PutAsJsonAsync(caminho + "/avaliacao",
            new { rating = 5, comment = "Restaurante muito bom", npsNota = 8 }), HttpStatusCode.OK);
        var avaliacaoId = primeira!["id"]!.GetValue<string>();
        var editada = await Json(cliente.PutAsJsonAsync(caminho + "/avaliacao",
            new { rating = 4, comment = "Restaurante continua bom" }), HttpStatusCode.OK);
        Assert.Equal(avaliacaoId, editada!["id"]!.GetValue<string>());
        Assert.Equal(8, editada["npsNota"]!.GetValue<int>());
        await Status(outroCliente.DeleteAsync("/api/restaurantes/avaliacoes/" + avaliacaoId), HttpStatusCode.NotFound);
        var simultaneas = Enumerable.Range(0, 4).Select(i => cliente.PutAsJsonAsync(caminho + "/avaliacao",
            new { rating = 4, comment = "Atualização simultânea " + i }));
        foreach (var resultado in await Task.WhenAll(simultaneas))
        {
            using (resultado) Assert.Equal(HttpStatusCode.OK, resultado.StatusCode);
        }
        var avaliacoes = await Json(cliente.GetAsync("/api/restaurantes/avaliacoes"), HttpStatusCode.OK);
        Assert.Single(avaliacoes!.AsArray(), a => a!["restaurantId"]!.GetValue<string>() == id.ToString());
        var ranking = await Json(publico.GetAsync("/api/restaurantes/ranking"), HttpStatusCode.OK);
        Assert.Equal(id.ToString(), ranking![0]!["id"]!.GetValue<string>());
        Assert.Equal(4m, ranking[0]!["media"]!.GetValue<decimal>());
        Assert.Equal(1, ranking[0]!["total"]!.GetValue<int>());
        using (var leitura = fixture.App.Services.CreateScope())
        {
            var repositorio = leitura.ServiceProvider.GetRequiredService<IRestauranteRepositorio>();
            Assert.Equal(4m, (await repositorio.ObterCompletoPorIdAsync(id, default))!.NotaMedia);
        }

        foreach (var conta in new[] { cliente, dono })
        {
            await Status(conta.PutAsJsonAsync("/api/perfil/favoritos/" + id, new { favorite = true }), HttpStatusCode.NoContent);
            await Status(conta.PutAsJsonAsync("/api/perfil/favoritos/" + id, new { favorite = true }), HttpStatusCode.NoContent);
            var favoritos = await Json(conta.GetAsync("/api/perfil/favoritos"), HttpStatusCode.OK);
            Assert.Equal(id.ToString(), Assert.Single(favoritos!.AsArray())!.GetValue<string>());
            var perfil = await Json(conta.PutAsJsonAsync("/api/perfil",
                new { name = "Nome atualizado", bio = "Bio do teste", avatar = "assets/images/avatar_1.jpg" }), HttpStatusCode.OK);
            Assert.Equal("Bio do teste", perfil!["bio"]!.GetValue<string>());
            await Status(conta.PutAsJsonAsync("/api/perfil/favoritos/" + id, new { favorite = false }), HttpStatusCode.NoContent);
        }
        Assert.Empty((await Json(outroCliente.GetAsync("/api/perfil/favoritos"), HttpStatusCode.OK))!.AsArray());

        using (var login = await publico.PostAsJsonAsync("/api/auth/login",
            new { email = "cliente@teste.example", senha = "senha-teste-123", role = "Cliente", documento = "12345678901" }))
        {
            Assert.Equal(HttpStatusCode.OK, login.StatusCode);
            var resultado = JsonNode.Parse(await login.Content.ReadAsStringAsync())!;
            Assert.Equal("Nome atualizado", resultado["user"]!["name"]!.GetValue<string>());
        }
        await Status(publico.PostAsJsonAsync("/api/auth/login",
            new { email = "cliente@teste.example", senha = "errada", role = "Cliente" }), HttpStatusCode.Unauthorized);
        await Status(publico.PostAsJsonAsync("/api/auth/registar",
            new { nome = "Duplicado", email = "CLIENTE@TESTE.EXAMPLE", senha = "senha-teste-123", cpf = "12345678903" }), HttpStatusCode.Conflict);
        await Status(cliente.DeleteAsync("/api/restaurantes/avaliacoes/" + avaliacaoId), HttpStatusCode.NoContent);
        await Status(cliente.PostAsync("/api/auth/sair", null), HttpStatusCode.NoContent);
        await Status(cliente.GetAsync("/api/perfil/favoritos"), HttpStatusCode.Unauthorized);

        // Também confirma que as contas CNPJ continuam compartilhadas com o site HTML.
        using var site = fixture.App.CreateClient(new WebApplicationFactoryClientOptions { HandleCookies = true });
        await Json(site.PostAsJsonAsync("/api/site/auth/login", new
        {
            email = "dono@teste.example", senha = "senha-teste-123", role = "Proprietario", documento = "12345678000190"
        }), HttpStatusCode.OK);
        await Json(site.GetAsync("/api/site/auth/sessao"), HttpStatusCode.OK);
        var listaSite = await Json(site.GetAsync("/api/site/auth/estabelecimentos"), HttpStatusCode.OK);
        Assert.Single(listaSite!.AsArray());
        await Status(site.PostAsJsonAsync($"/api/site/auth/estabelecimentos/{id}/fotos",
            new { arquivo = Foto, legenda = "Foto pelo site" }), HttpStatusCode.NoContent);
        await Status(site.PostAsync("/api/site/auth/sair", null), HttpStatusCode.NoContent);
        await Status(site.GetAsync("/api/site/auth/sessao"), HttpStatusCode.Unauthorized);

        var busca = await Json(publico.GetAsync("/api/restaurantes?cidade=S%C3%A3o%20Paulo&bairro=Centro&tamanho=50"), HttpStatusCode.OK);
        Assert.Contains(busca!.AsArray(), r => r!["id"]!.GetValue<string>() == id.ToString());
        using var escopo = fixture.App.Services.CreateScope();
        var banco = escopo.ServiceProvider.GetRequiredService<BuillonContext>();
        Assert.Equal(14, banco.Model.GetEntityTypes().Count());
        var senhaSalva = await banco.Usuarios.Where(u => u.Email == "cliente@teste.example").Select(u => u.SenhaHash).SingleAsync();
        Assert.NotEqual("senha-teste-123", senhaSalva);
    }

    private async Task<HttpClient> Cadastrar(string nome, string documento, bool proprietario)
    {
        var cliente = fixture.App.CreateClient();
        var sessao = await Json(cliente.PostAsJsonAsync("/api/auth/registar", new
        {
            nome, email = nome + "@teste.example", senha = "senha-teste-123",
            cpf = proprietario ? null : documento, documento = proprietario ? documento : null,
            role = proprietario ? "Proprietario" : "Cliente"
        }), HttpStatusCode.Created);
        cliente.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", sessao!["token"]!.GetValue<string>());
        return cliente;
    }

    private static async Task<JsonNode?> Json(Task<HttpResponseMessage> tarefa, HttpStatusCode esperado)
    {
        using var resposta = await tarefa;
        var texto = await resposta.Content.ReadAsStringAsync();
        Assert.True(resposta.StatusCode == esperado, $"HTTP esperado {(int)esperado}, recebido {(int)resposta.StatusCode}: {texto}");
        return JsonNode.Parse(texto);
    }

    private static async Task Status(Task<HttpResponseMessage> tarefa, HttpStatusCode esperado)
    {
        using var resposta = await tarefa;
        Assert.True(resposta.StatusCode == esperado,
            $"HTTP esperado {(int)esperado}, recebido {(int)resposta.StatusCode}: {await resposta.Content.ReadAsStringAsync()}");
    }
}

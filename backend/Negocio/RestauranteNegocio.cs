using Buillon.Modelos;
using Buillon.Repositorio;

namespace Buillon.Negocio;

public sealed class RestauranteNegocio(IRestauranteRepositorio restaurantes, AvaliacaoRepositorio avaliacoes)
{
    public async Task<List<RestauranteResposta>> ListarDoProprietarioAsync(int fornecedor, int pagina, CancellationToken ct)
    {
        if (pagina is < 1 or > 1_000_000) throw new ApiException(400, "Informe uma página válida.");
        return (await restaurantes.ListarDoProprietarioAsync(fornecedor, pagina, ct)).Select(r => ParaResposta(r, true)).ToList();
    }

    public async Task<List<RestauranteResposta>> ListarNaAreaAsync(string? cidade, string? bairro, int pagina, int tamanho,
        CancellationToken ct)
    {
        if (pagina is < 1 or > 1_000_000 || tamanho is < 1 or > 50)
            throw new ApiException(400, "Informe uma página válida e um tamanho de 1 a 50.");
        return (await restaurantes.ListarPorAreaAsync(Opcional(cidade, 50), Opcional(bairro, 50), pagina, tamanho, ct))
            .Select(r => ParaResposta(r, false)).ToList();
    }

    public async Task<RestauranteResposta> ObterPorIdAsync(int id, CancellationToken ct) =>
        ParaResposta(await restaurantes.ObterCompletoPorIdAsync(id, ct)
            ?? throw new ApiException(404, "Restaurante não encontrado."), false);

    public Task<int> CadastrarRestauranteAsync(SalvarRestauranteDto dto, int proprietarioId, CancellationToken ct) =>
        SalvarAsync(null, proprietarioId, dto, ct);

    public Task<int> EditarPaginaDoEstabelecimentoAsync(int id, int proprietarioId, SalvarRestauranteDto dto, CancellationToken ct) =>
        SalvarAsync(id, proprietarioId, dto, ct);

    public Task<int> SalvarAsync(int? id, int fornecedor, SalvarRestauranteDto dto, CancellationToken ct,
        string? arquivo = null)
    {
        var cnpj = AutenticacaoNegocio.NormalizarDocumento(dto.Cnpj);
        var cep = AutenticacaoNegocio.NormalizarDocumento(dto.Cep);
        if ((id is null || cnpj.Length > 0) && (cnpj.Length != 14 || !cnpj.All(char.IsAsciiDigit)))
            throw new ApiException(400, "Informe o CNPJ com 14 dígitos.");
        if (cep.Length > 0 && (cep.Length != 8 || !cep.All(char.IsAsciiDigit)))
            throw new ApiException(400, "Informe o CEP com 8 dígitos.");
        return restaurantes.SalvarAsync(id, fornecedor, dto with
        {
            Nome = Obrigatorio(dto.Nome, "Nome do restaurante", 3, 100),
            Rua = Obrigatorio(dto.Rua, "Rua", 1, 100),
            Cidade = Obrigatorio(dto.Cidade, "Cidade", 1, 50),
            Descricao = Opcional(dto.Descricao, 1000),
            Numero = Opcional(dto.Numero, 100),
            Bairro = Opcional(dto.Bairro, 50),
            Estado = Opcional(dto.Estado, 2)?.ToUpperInvariant(),
            Cep = cep.Length == 0 ? null : cep,
            Cnpj = cnpj.Length == 0 ? null : cnpj,
            Telefone = Opcional(dto.Telefone, 20)
        }, ct, LerImagem(arquivo));
    }

    public Task AdicionarItemCardapioAsync(int id, int fornecedor, ItemCardapioDto dto, CancellationToken ct)
    {
        if (dto.Preco is < 0.01m or > 99_999_999.99m || decimal.Round(dto.Preco, 2) != dto.Preco)
            throw new ApiException(400, "Informe um preço positivo com até duas casas decimais.");
        var imagem = LerImagem(dto.Arquivo);
        return restaurantes.AdicionarItemCardapioAsync(id, fornecedor, dto with
        {
            Nome = Obrigatorio(dto.Nome, "Nome do prato", 1, 100),
            Descricao = Opcional(dto.Descricao, 300) ?? "",
            Imagem = imagem is null ? UrlImagem(dto.Imagem, false) : null
        }, imagem, ct);
    }

    public Task AdicionarFotoAsync(int id, int fornecedor, FotoRestauranteDto dto, CancellationToken ct)
    {
        var imagem = LerImagem(dto.Arquivo);
        return restaurantes.AdicionarFotoAsync(id, fornecedor, dto with
        {
            Url = imagem is null ? UrlImagem(dto.Url, true) : null,
            Legenda = Opcional(dto.Legenda, 150) ?? ""
        }, imagem, ct);
    }

    public Task PublicarAsync(int id, int fornecedor, PublicacaoDto dto, CancellationToken ct) =>
        restaurantes.PublicarAsync(id, fornecedor, Obrigatorio(dto.Comentario, "Comentário", 1, 1000), ct);

    private static ImagemEstabelecimento? LerImagem(string? arquivo)
    {
        const int limite = 5 * 1024 * 1024;
        if (arquivo is null) return null;
        if (arquivo.Length > ((limite + 2) / 3) * 4)
            throw new ApiException(400, "Escolha uma foto de até 5 MB.");
        byte[] dados;
        try { dados = Convert.FromBase64String(arquivo); }
        catch (FormatException) { throw new ApiException(400, "Arquivo de imagem inválido."); }
        if (dados.Length > limite) throw new ApiException(400, "Escolha uma foto de até 5 MB.");

        var tipo = dados.AsSpan().StartsWith(new byte[] { 255, 216, 255 }) ? "image/jpeg"
            : dados.AsSpan().StartsWith(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }) ? "image/png"
            : dados.Length >= 12 && dados.AsSpan(0, 4).SequenceEqual("RIFF"u8)
                && dados.AsSpan(8, 4).SequenceEqual("WEBP"u8) ? "image/webp" : null;
        return tipo is null ? throw new ApiException(400, "Selecione uma foto JPG, PNG ou WebP.") : new(tipo, dados);
    }

    public Task<AvaliacaoResposta> AvaliarRestauranteAsync(int restaurante, int cliente, SalvarAvaliacaoDto dto,
        CancellationToken ct)
    {
        if (dto.Rating is < 1 or > 5 || dto.NpsNota is < 0 or > 10)
            throw new ApiException(400, "Use de 1 a 5 estrelas e, se preenchido, um NPS de 0 a 10.");
        return avaliacoes.SalvarAsync(cliente, restaurante, dto.Rating,
            Obrigatorio(dto.Comment, "Comentário", 10, 1000), dto.NpsNota, ct);
    }

    private static RestauranteResposta ParaResposta(Restaurante r, bool incluirDados)
    {
        var endereco = r.EnderecoPrincipal;
        return new(RestauranteRepositorio.Chave(r.Id), r.Nome, r.Categoria?.Nome ?? "", r.Bairro,
            r.EnderecoCompleto, r.Descricao ?? "", r.Fotos.OrderBy(f => f.Id).FirstOrDefault()?.UrlFoto ?? "",
            r.FaixaPreco ?? "", r.Horario ?? "",
            r.Cardapio.OrderBy(i => i.Id).Select(i => new ItemCardapioResposta(i.NomePrato, i.Descricao, i.Imagem, i.Preco)).ToList(),
            r.Fotos.OrderBy(f => f.Id).Select(f => new FotoRestauranteResposta(f.UrlFoto, f.Legenda)).ToList(),
            r.Publicacoes.OrderByDescending(p => p.Id).Select(p => new PublicacaoResposta(p.Id, p.Comentario, p.CriadoEm)).ToList(),
            incluirDados ? new DadosEstabelecimento(r.CategoriaId, r.Cnpj ?? "", endereco?.Rua ?? "",
                endereco?.Numero ?? "", r.Bairro, r.Cidade, endereco?.Estado ?? "", endereco?.Cep ?? "", r.Telefone ?? "") : null,
            r.ChaveExemplo is not null);
    }

    internal static string Obrigatorio(string? valor, string campo, int minimo, int maximo)
    {
        valor = valor?.Trim() ?? "";
        return valor.Length >= minimo && valor.Length <= maximo
            ? valor : throw new ApiException(400, $"{campo} deve ter de {minimo} a {maximo} caracteres.");
    }

    internal static string? Opcional(string? valor, int maximo) => string.IsNullOrWhiteSpace(valor)
        ? null : Obrigatorio(valor, "O campo informado", 1, maximo);

    private static string UrlImagem(string? valor, bool obrigatorio)
    {
        var url = Opcional(valor, 500);
        if (url is null && !obrigatorio) return "";
        if (url is not null && url.StartsWith("https://", StringComparison.Ordinal)
            && Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Host.Length > 0)
            return url;
        throw new ApiException(400, "Informe um endereço HTTPS para a imagem.");
    }
}

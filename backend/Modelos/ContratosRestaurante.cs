namespace Buillon.Modelos;

// DTOs mantêm o JSON que o aplicativo Flutter e o site já consomem.
public sealed record ItemCardapioResposta(string Name, string Description, string Image, decimal? Price);
public sealed record FotoRestauranteResposta(string Url, string Legenda);
public sealed record PublicacaoResposta(int Id, string Comentario, DateTime CriadoEm);
public sealed record ImagemEstabelecimento(string Tipo, byte[] Dados);
public sealed record DadosEstabelecimento(int CategoriaId, string Cnpj, string Rua, string Numero, string Bairro,
    string Cidade, string Estado, string Cep, string Telefone);
public sealed record RestauranteResposta(string Id, string Name, string Category, string Neighborhood,
    string Address, string Description, string Image, string Price, string Hours,
    IReadOnlyList<ItemCardapioResposta> Dishes, IReadOnlyList<FotoRestauranteResposta> Fotos,
    IReadOnlyList<PublicacaoResposta> Publicacoes, DadosEstabelecimento? Dados, bool IsExample);
public sealed record PosicaoRanking(string Id, string Nome, string Categoria, long Total, decimal Media, long Posicao);
public sealed record AvaliacaoResposta(string Id, string RestaurantId, string UserId, string UserName,
    string UserAvatar, int Rating, string Comment, DateTime? CreatedAt, int? NpsNota);

public sealed record SalvarRestauranteDto(string? Nome, string? Descricao, string? Rua, string? Numero,
    string? Bairro, string? Cidade, string? Estado, string? Cep, string? Telefone, int CategoriaId, string? Cnpj);
public sealed record CadastroEstabelecimentoSiteDto(string? Nome, string? Descricao, string? Rua, string? Numero,
    string? Bairro, string? Cidade, string? Estado, string? Cep, string? Telefone, int CategoriaId, string? Cnpj,
    string? Arquivo);
public sealed record ItemCardapioDto(string? Nome, string? Descricao, string? Imagem, decimal Preco, string? Arquivo);
public sealed record FotoRestauranteDto(string? Url, string? Legenda, string? Arquivo);
public sealed record PublicacaoDto(string? Comentario);
public sealed record SalvarAvaliacaoDto(int Rating, string? Comment, int? NpsNota);
public sealed record SalvarFavoritoDto(bool? Favorite);

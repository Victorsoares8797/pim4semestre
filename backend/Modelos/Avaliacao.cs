namespace Buillon.Modelos;

public sealed record Avaliacao(string Id, string RestaurantId, string UserId, string UserName,
    string UserAvatar, int Rating, string Comment, DateTime? CreatedAt, int? NpsNota);
public sealed record SalvarAvaliacaoDto(int Rating, string? Comment, int? NpsNota);
public sealed record SalvarFavoritoDto(bool? Favorite);

namespace Buillon.Modelos;

public static class Perfis
{
    public const string Cliente = "Cliente";
    public const string Proprietario = "Proprietario";
    public const string AvatarPadrao = "";
}

public sealed record PerfilUsuario(string Id, string Name, string Email, string Avatar, string Bio);
public sealed record SessaoUsuario(string Token, PerfilUsuario User, string Role);
public sealed record LoginDto(string? Email, string? Senha, string? Role, string? Documento);
public sealed record RegistoUsuarioDto(string? Nome, string? Email, string? Senha, string? Cpf,
    string? Role, string? Documento);
public sealed record AtualizarPerfilDto(string? Name, string? Bio, string? Avatar);

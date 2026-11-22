using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Buillon.Modelos;

public class Usuario : EntidadeBase
{
    [Required, MaxLength(100)] public string Nome { get; set; } = "";
    [Required, EmailAddress, MaxLength(100)] public string Email { get; set; } = "";
    [Required] public string SenhaHash { get; set; } = "";
    public string Documento { get; set; } = "";
    [NotMapped] public string Role { get; set; } = Perfis.Cliente;
    public PerfilCliente? Perfil { get; set; }

    public override void Validar()
    {
        if (string.IsNullOrWhiteSpace(Nome)) throw new ArgumentException("O nome do usuário é obrigatório.");
        if (!new EmailAddressAttribute().IsValid(Email)) throw new ArgumentException("E-mail inválido.");
        if (Role is not (Perfis.Cliente or Perfis.Proprietario))
            throw new ArgumentException("O perfil deve ser Cliente ou Proprietario.");
    }

    public PerfilUsuario ParaPerfil() => new(Id.ToString(System.Globalization.CultureInfo.InvariantCulture),
        Nome, Email, Perfil?.Avatar ?? Perfis.AvatarPadrao, Perfil?.Bio ?? "");
}

// FORNECEDOR é separado de CLIENTE no SQL original; não existe uma tabela Usuarios.
public class Fornecedor
{
    public int Id { get; set; }
    public string NomeResponsavel { get; set; } = "";
    public string Documento { get; set; } = "";
    public string? Email { get; set; }
    public string? SenhaHash { get; set; }
    public PerfilFornecedor? Perfil { get; set; }

    public Usuario ParaUsuario() => new()
    {
        Id = Id, Nome = NomeResponsavel, Email = Email ?? "", SenhaHash = SenhaHash ?? "",
        Documento = Documento, Role = Perfis.Proprietario,
        Perfil = Perfil is null ? null : new PerfilCliente { UsuarioId = Id, Bio = Perfil.Bio, Avatar = Perfil.Avatar }
    };
}

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

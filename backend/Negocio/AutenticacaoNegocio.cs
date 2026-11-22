using System.ComponentModel.DataAnnotations;
using Buillon.Modelos;
using Buillon.Repositorio;
using Microsoft.AspNetCore.Identity;

namespace Buillon.Negocio;

public sealed class AutenticacaoNegocio(IUsuarioRepositorio usuarios, IPasswordHasher<string> hasher,
    SessaoNegocio sessoes)
{
    public async Task<SessaoUsuario> RegistarUsuarioAsync(RegistoUsuarioDto dto, CancellationToken ct)
    {
        var role = Role(dto.Role);
        var nome = dto.Nome?.Trim() ?? "";
        var email = dto.Email?.Trim().ToLowerInvariant() ?? "";
        var senha = dto.Senha ?? "";
        if (nome.Length is < 2 or > 60 || email.Length > 100 || !new EmailAddressAttribute().IsValid(email)
            || senha.Length is < 6 or > 128 || string.IsNullOrWhiteSpace(senha))
            throw new ApiException(400, "Confira nome, e-mail e senha de 6 a 128 caracteres.");

        var documento = NormalizarDocumento(role == Perfis.Cliente ? dto.Cpf : dto.Documento);
        if (role == Perfis.Cliente && (documento.Length != 11 || !documento.All(char.IsAsciiDigit)))
            throw new ApiException(400, "Informe o CPF com 11 dígitos.");
        if (role == Perfis.Proprietario && (documento.Length != 14 || !documento.All(char.IsAsciiDigit)))
            throw new ApiException(400, "Informe o CNPJ com 14 dígitos.");

        var usuario = new Usuario
        {
            Nome = nome, Email = email, Documento = documento, Role = role,
            SenhaHash = hasher.HashPassword(email, senha)
        };
        usuario.Validar();
        await usuarios.AdicionarAsync(usuario, ct);
        return sessoes.Abrir(usuario.ParaPerfil(), role);
    }

    public async Task<SessaoUsuario> ValidarLoginAsync(LoginDto dto, CancellationToken ct)
    {
        var role = Role(dto.Role);
        var email = dto.Email?.Trim().ToLowerInvariant() ?? "";
        var senha = dto.Senha ?? "";
        var documento = dto.Documento is null ? null : NormalizarDocumento(dto.Documento);
        if (email.Length is 0 or > 100 || senha.Length is 0 or > 128)
            throw CredenciaisInvalidas();
        if (documento is not null &&
            (!documento.All(char.IsAsciiDigit) ||
             (role == Perfis.Cliente ? documento.Length != 11 : documento.Length is not (11 or 14))))
            throw CredenciaisInvalidas();

        var conta = await usuarios.ObterPorEmailAsync(email, role, documento, ct);
        if (conta is null || !VerificarSenha(email, conta.SenhaHash, senha))
            throw CredenciaisInvalidas();
        return sessoes.Abrir(conta.ParaPerfil(), role);
    }

    private bool VerificarSenha(string email, string hash, string senha)
    {
        try
        {
            return hasher.VerifyHashedPassword(email, hash, senha) != PasswordVerificationResult.Failed;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static string Role(string? role) => role switch
    {
        null or "" or Perfis.Cliente => Perfis.Cliente,
        Perfis.Proprietario => Perfis.Proprietario,
        _ => throw new ApiException(400, "Selecione um tipo de conta válido.")
    };

    internal static string NormalizarDocumento(string? value) =>
        string.Concat((value ?? "").Where(c => !char.IsWhiteSpace(c) && c is not ('.' or '-' or '/')));

    private static ApiException CredenciaisInvalidas() => new(401, "Confira o documento, o e-mail e a senha.");
}

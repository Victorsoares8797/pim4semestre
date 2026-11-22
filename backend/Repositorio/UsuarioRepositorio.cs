using Buillon.Modelos;
using Buillon.Negocio;
using Microsoft.EntityFrameworkCore;

namespace Buillon.Repositorio;

public class UsuarioRepositorio(BuillonContext context) : IUsuarioRepositorio
{
    public async Task<Usuario?> ObterPorEmailAsync(string email, string role = Perfis.Cliente,
        string? documento = null, CancellationToken ct = default)
    {
        if (role == Perfis.Proprietario)
        {
            var conta = await context.Fornecedores.AsNoTracking().Include(f => f.Perfil)
                .SingleOrDefaultAsync(f => f.Email != null && f.Email.Trim().ToLower() == email, ct);
            return conta is not null && ConfereDocumento(conta.Documento, documento) ? conta.ParaUsuario() : null;
        }
        var usuario = await context.Usuarios.AsNoTracking().Include(u => u.Perfil)
            .SingleOrDefaultAsync(u => u.Email.Trim().ToLower() == email, ct);
        return usuario is not null && ConfereDocumento(usuario.Documento, documento) ? usuario : null;
    }

    public Task<Usuario?> ObterPorIdAsync(int id, CancellationToken ct = default) =>
        context.Usuarios.AsNoTracking().Include(u => u.Perfil).SingleOrDefaultAsync(u => u.Id == id, ct);

    public async Task AdicionarAsync(Usuario usuario, CancellationToken ct = default)
    {
        usuario.Validar();
        if (usuario.Role == Perfis.Proprietario)
        {
            var fornecedor = new Fornecedor
            {
                NomeResponsavel = usuario.Nome, Email = usuario.Email,
                Documento = usuario.Documento, SenhaHash = usuario.SenhaHash
            };
            context.Fornecedores.Add(fornecedor);
            await context.SaveChangesAsync(ct);
            usuario.Id = fornecedor.Id;
        }
        else
        {
            context.Usuarios.Add(usuario);
            await context.SaveChangesAsync(ct);
        }
    }

    public async Task<PerfilUsuario> AtualizarPerfilAsync(int id, bool proprietario, string nome,
        string bio, string avatar, CancellationToken ct)
    {
        // O bloqueio da conta serializa a criação do perfil em chamadas simultâneas.
        await using var transaction = await context.Database.BeginTransactionAsync(ct);
        Usuario usuario;
        if (proprietario)
        {
            var conta = await context.Fornecedores
                .FromSqlInterpolated($"SELECT * FROM buillon.fornecedor WHERE id_fornecedor = {id} FOR UPDATE")
                .SingleOrDefaultAsync(ct) ?? throw new ApiException(404, "Conta não encontrada.");
            await context.Entry(conta).Reference(f => f.Perfil).LoadAsync(ct);
            conta.NomeResponsavel = nome;
            conta.Perfil ??= new PerfilFornecedor { FornecedorId = id };
            conta.Perfil.Bio = bio; conta.Perfil.Avatar = avatar;
            usuario = conta.ParaUsuario();
        }
        else
        {
            usuario = await context.Usuarios
                .FromSqlInterpolated($"SELECT * FROM buillon.cliente WHERE id_cliente = {id} FOR UPDATE")
                .SingleOrDefaultAsync(ct) ?? throw new ApiException(404, "Conta não encontrada.");
            await context.Entry(usuario).Reference(u => u.Perfil).LoadAsync(ct);
            usuario.Nome = nome;
            usuario.Perfil ??= new PerfilCliente { UsuarioId = id };
            usuario.Perfil.Bio = bio; usuario.Perfil.Avatar = avatar;
        }
        await context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return usuario.ParaPerfil();
    }

    private static bool ConfereDocumento(string salvo, string? informado) =>
        informado is null || AutenticacaoNegocio.NormalizarDocumento(salvo) == informado;
}

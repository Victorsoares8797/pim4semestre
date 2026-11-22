using Buillon.Modelos;

namespace Buillon.Repositorio;

public interface IUsuarioRepositorio
{
    Task<Usuario?> ObterPorEmailAsync(string email, string role = Perfis.Cliente,
        string? documento = null, CancellationToken ct = default);
    Task<Usuario?> ObterPorIdAsync(int id, CancellationToken ct = default);
    Task AdicionarAsync(Usuario usuario, CancellationToken ct = default);
    Task<PerfilUsuario> AtualizarPerfilAsync(int id, bool proprietario, string nome, string bio, string avatar,
        CancellationToken ct);
}

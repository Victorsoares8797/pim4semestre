namespace Buillon.Modelos;

// Entidades das tabelas já existentes no esquema buillon do Supabase.
public class Categoria
{
    public int Id { get; set; }
    public string Nome { get; set; } = "";
}

public class Endereco
{
    public int Id { get; set; }
    public int RestauranteId { get; set; }
    public string? Rua { get; set; }
    public string? Numero { get; set; }
    public string? Bairro { get; set; }
    public string? Cidade { get; set; }
    public string? Estado { get; set; }
    public string? Cep { get; set; }
    public string Completo => string.Join(", ", new[]
    {
        string.Join(" ", new[] { Rua, Numero }.Where(s => !string.IsNullOrEmpty(s))), Bairro, Cidade, Estado, Cep
    }.Where(s => !string.IsNullOrEmpty(s)));
}

public class PerfilCliente
{
    public int UsuarioId { get; set; }
    public string Bio { get; set; } = "";
    public string Avatar { get; set; } = "";
}

public class PerfilFornecedor
{
    public int FornecedorId { get; set; }
    public string Bio { get; set; } = "";
    public string Avatar { get; set; } = "";
}

public class FavoritoCliente
{
    public int UsuarioId { get; set; }
    public int RestauranteId { get; set; }
}

public class FavoritoFornecedor
{
    public int FornecedorId { get; set; }
    public int RestauranteId { get; set; }
}

public class ArquivoImagem
{
    public Guid Id { get; set; }
    public int RestauranteId { get; set; }
    public string Tipo { get; set; } = "";
    public byte[] Dados { get; set; } = [];
}

public class PublicacaoEstabelecimento
{
    public int Id { get; set; }
    public int RestauranteId { get; set; }
    public string Comentario { get; set; } = "";
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Buillon.Modelos;

public class Restaurante : EntidadeBase
{
    [Required, MaxLength(100)] public string Nome { get; private set; } = "";
    public string? Descricao { get; private set; }
    public string? Telefone { get; private set; }
    public string? Cnpj { get; set; }
    public string? Status { get; set; } = "Pendente";
    public int ProprietarioId { get; set; }
    public Fornecedor? Proprietario { get; private set; }
    public int CategoriaId { get; set; }
    public Categoria? Categoria { get; private set; }
    public string? ChaveExemplo { get; private set; }
    public string? FaixaPreco { get; private set; }
    public string? Horario { get; private set; }
    public ICollection<Endereco> Enderecos { get; private set; } = new List<Endereco>();
    public ICollection<ItemCardapio> Cardapio { get; private set; } = new List<ItemCardapio>();
    public ICollection<FotoRestaurante> Fotos { get; private set; } = new List<FotoRestaurante>();
    public ICollection<Avaliacao> Avaliacoes { get; private set; } = new List<Avaliacao>();
    public ICollection<PublicacaoEstabelecimento> Publicacoes { get; private set; } = new List<PublicacaoEstabelecimento>();

    [NotMapped] public Endereco? EnderecoPrincipal => Enderecos.OrderBy(e => e.Id).FirstOrDefault();
    [NotMapped] public string EnderecoCompleto => EnderecoPrincipal?.Completo ?? "";
    [NotMapped] public string Bairro => EnderecoPrincipal?.Bairro ?? "";
    [NotMapped] public string Cidade => EnderecoPrincipal?.Cidade ?? "";
    [NotMapped] public decimal NotaMedia => (decimal)(Avaliacoes.Where(a => a.Nota != null).Average(a => (double?)a.Nota) ?? 0);

    protected Restaurante() { } // Utilizado pelo Entity Framework.

    public Restaurante(string nome, string descricao, string endereco, string bairro, string cidade,
        string telefone, int proprietarioId)
    {
        ProprietarioId = proprietarioId;
        AtualizarPagina(nome, descricao, endereco, bairro, cidade, telefone);
    }

    public void AtualizarPagina(string nome, string descricao, string endereco, string bairro, string cidade, string telefone)
    {
        Nome = nome; Descricao = descricao; Telefone = telefone;
        var principal = EnderecoPrincipal;
        if (principal is null) { principal = new Endereco(); Enderecos.Add(principal); }
        principal.Rua = endereco; principal.Bairro = bairro; principal.Cidade = cidade;
        Validar();
    }

    public override void Validar()
    {
        if (string.IsNullOrWhiteSpace(Nome) || Nome.Length < 3)
            throw new ArgumentException("O nome do restaurante deve ter pelo menos 3 caracteres.");
        if (string.IsNullOrWhiteSpace(EnderecoCompleto) || string.IsNullOrWhiteSpace(Cidade))
            throw new ArgumentException("O endereço e a cidade são obrigatórios.");
    }
}

public class ItemCardapio : EntidadeBase
{
    public int RestauranteId { get; set; }
    [Required, MaxLength(100)] public string NomePrato { get; set; } = "";
    [MaxLength(300)] public string Descricao { get; set; } = "";
    public decimal? Preco { get; set; } // O catálogo de exemplo não informa preço individual.
    public string Imagem { get; set; } = "";
    public override void Validar()
    {
        if (string.IsNullOrWhiteSpace(NomePrato)) throw new ArgumentException("O nome do prato é obrigatório.");
        if (Preco is null or <= 0) throw new ArgumentException("O preço precisa ser maior que zero.");
    }
}

public class FotoRestaurante : EntidadeBase
{
    public int RestauranteId { get; set; }
    [Required, MaxLength(500)] public string UrlFoto { get; set; } = "";
    [MaxLength(150)] public string Legenda { get; set; } = "";
    public override void Validar()
    {
        if (string.IsNullOrWhiteSpace(UrlFoto)) throw new ArgumentException("O endereço da foto é obrigatório.");
    }
}

using System.ComponentModel.DataAnnotations;

namespace Buillon.Modelos;

public class Avaliacao : EntidadeBase
{
    public int RestauranteId { get; set; }
    public int UsuarioId { get; set; }
    public Usuario? Usuario { get; set; }
    public int? Nota { get; set; }
    public int? NpsNota { get; set; }
    [MaxLength(1000)] public string? Comentario { get; set; }
    public DateTime? DataAvaliacao { get; set; }
    public override void Validar()
    {
        if (Nota is null or < 1 or > 5) throw new ArgumentException("A avaliação deve ter uma nota entre 1 e 5.");
    }
}

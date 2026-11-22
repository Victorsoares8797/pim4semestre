using System.ComponentModel.DataAnnotations.Schema;

namespace Buillon.Modelos;

// Mesma base do código enviado. Só CLIENTE possui uma coluna de data de cadastro.
public abstract class EntidadeBase
{
    public int Id { get; set; }
    [NotMapped]
    public DateTime DataCriacao { get; protected set; } = DateTime.UtcNow;
    public abstract void Validar();
}

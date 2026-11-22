using Buillon.Modelos;
using Microsoft.EntityFrameworkCore;

namespace Buillon.Repositorio;

// Mesmo DbContext do código original, agora mapeado às tabelas reais do PostgreSQL.
public class BuillonContext(DbContextOptions<BuillonContext> options) : DbContext(options)
{
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Fornecedor> Fornecedores => Set<Fornecedor>();
    public DbSet<Restaurante> Restaurantes => Set<Restaurante>();
    public DbSet<Categoria> Categorias => Set<Categoria>();
    public DbSet<Endereco> Enderecos => Set<Endereco>();
    public DbSet<ItemCardapio> ItensCardapio => Set<ItemCardapio>();
    public DbSet<FotoRestaurante> FotosRestaurante => Set<FotoRestaurante>();
    public DbSet<Avaliacao> Avaliacoes => Set<Avaliacao>();
    public DbSet<PerfilCliente> PerfisClientes => Set<PerfilCliente>();
    public DbSet<PerfilFornecedor> PerfisFornecedores => Set<PerfilFornecedor>();
    public DbSet<FavoritoCliente> FavoritosClientes => Set<FavoritoCliente>();
    public DbSet<FavoritoFornecedor> FavoritosFornecedores => Set<FavoritoFornecedor>();
    public DbSet<ArquivoImagem> Imagens => Set<ArquivoImagem>();
    public DbSet<PublicacaoEstabelecimento> Publicacoes => Set<PublicacaoEstabelecimento>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema("buillon");
        // A herança compartilha código C#, sem criar tabela EntidadeBase ou discriminador.
        modelBuilder.Ignore<EntidadeBase>();
        var usuario = modelBuilder.Entity<Usuario>();
        usuario.HasBaseType((Type?)null);
        usuario.ToTable("cliente");
        usuario.HasKey(u => u.Id);
        usuario.Property(u => u.Id).HasColumnName("id_cliente");
        usuario.Property(u => u.Nome).HasColumnName("nome");
        usuario.Property(u => u.Email).HasColumnName("email");
        usuario.Property(u => u.SenhaHash).HasColumnName("senha");
        usuario.Property(u => u.Documento).HasColumnName("cpf").HasMaxLength(11);
        usuario.Property(u => u.DataCriacao).HasColumnName("data_cadastro");
        usuario.HasOne(u => u.Perfil).WithOne().HasForeignKey<PerfilCliente>(p => p.UsuarioId);

        var fornecedor = modelBuilder.Entity<Fornecedor>();
        fornecedor.ToTable("fornecedor");
        fornecedor.HasKey(f => f.Id);
        fornecedor.Property(f => f.Id).HasColumnName("id_fornecedor");
        fornecedor.Property(f => f.NomeResponsavel).HasColumnName("nome_responsavel").HasMaxLength(100);
        fornecedor.Property(f => f.Documento).HasColumnName("documento").HasMaxLength(18);
        fornecedor.Property(f => f.Email).HasColumnName("email").HasMaxLength(100);
        fornecedor.Property(f => f.SenhaHash).HasColumnName("senha").HasMaxLength(255);
        fornecedor.HasOne(f => f.Perfil).WithOne().HasForeignKey<PerfilFornecedor>(p => p.FornecedorId);

        var restaurante = modelBuilder.Entity<Restaurante>();
        restaurante.HasBaseType((Type?)null);
        restaurante.ToTable("estabelecimento");
        restaurante.HasKey(r => r.Id);
        restaurante.Property(r => r.Id).HasColumnName("id_estabelecimento");
        restaurante.Property(r => r.Nome).HasColumnName("nome_fantasia");
        restaurante.Property(r => r.Descricao).HasColumnName("descricao");
        restaurante.Property(r => r.Telefone).HasColumnName("telefone").HasMaxLength(20);
        restaurante.Property(r => r.Cnpj).HasColumnName("cnpj").HasMaxLength(14);
        restaurante.Property(r => r.Status).HasColumnName("status").HasMaxLength(20);
        restaurante.Property(r => r.ProprietarioId).HasColumnName("id_fornecedor");
        restaurante.Property(r => r.CategoriaId).HasColumnName("id_categoria");
        restaurante.Property(r => r.ChaveExemplo).HasColumnName("chave_exemplo");
        restaurante.Property(r => r.FaixaPreco).HasColumnName("faixa_preco");
        restaurante.Property(r => r.Horario).HasColumnName("horario");
        restaurante.HasOne(r => r.Proprietario).WithMany().HasForeignKey(r => r.ProprietarioId);
        restaurante.HasOne(r => r.Categoria).WithMany().HasForeignKey(r => r.CategoriaId);
        restaurante.HasMany(r => r.Enderecos).WithOne().HasForeignKey(e => e.RestauranteId);
        restaurante.HasMany(r => r.Cardapio).WithOne().HasForeignKey(i => i.RestauranteId);
        restaurante.HasMany(r => r.Fotos).WithOne().HasForeignKey(f => f.RestauranteId);
        restaurante.HasMany(r => r.Avaliacoes).WithOne().HasForeignKey(a => a.RestauranteId);
        restaurante.HasMany(r => r.Publicacoes).WithOne().HasForeignKey(p => p.RestauranteId);

        var categoria = modelBuilder.Entity<Categoria>();
        categoria.ToTable("categoria");
        categoria.HasKey(c => c.Id);
        categoria.Property(c => c.Id).HasColumnName("id_categoria");
        categoria.Property(c => c.Nome).HasColumnName("nome_categoria").HasMaxLength(60);

        var endereco = modelBuilder.Entity<Endereco>();
        endereco.ToTable("endereco");
        endereco.HasKey(e => e.Id);
        endereco.Ignore(e => e.Completo);
        endereco.Property(e => e.Id).HasColumnName("id_endereco");
        endereco.Property(e => e.RestauranteId).HasColumnName("id_estabelecimento");
        endereco.Property(e => e.Rua).HasColumnName("rua").HasMaxLength(100);
        endereco.Property(e => e.Numero).HasColumnName("numero").HasMaxLength(100);
        endereco.Property(e => e.Bairro).HasColumnName("bairro").HasMaxLength(50);
        endereco.Property(e => e.Cidade).HasColumnName("cidade").HasMaxLength(50);
        endereco.Property(e => e.Estado).HasColumnName("estado").HasMaxLength(2);
        endereco.Property(e => e.Cep).HasColumnName("cep").HasMaxLength(8);

        var item = modelBuilder.Entity<ItemCardapio>();
        item.HasBaseType((Type?)null);
        item.ToTable("buillon_app_cardapio");
        item.HasKey(i => i.Id);
        item.Property(i => i.Id).HasColumnName("id_item");
        item.Property(i => i.RestauranteId).HasColumnName("id_estabelecimento");
        item.Property(i => i.NomePrato).HasColumnName("nome");
        item.Property(i => i.Descricao).HasColumnName("descricao");
        item.Property(i => i.Preco).HasColumnName("preco").HasPrecision(10, 2);
        item.Property(i => i.Imagem).HasColumnName("imagem").HasMaxLength(500);

        var foto = modelBuilder.Entity<FotoRestaurante>();
        foto.HasBaseType((Type?)null);
        foto.ToTable("buillon_app_foto");
        foto.HasKey(f => f.Id);
        foto.Property(f => f.Id).HasColumnName("id_foto");
        foto.Property(f => f.RestauranteId).HasColumnName("id_estabelecimento");
        foto.Property(f => f.UrlFoto).HasColumnName("url");
        foto.Property(f => f.Legenda).HasColumnName("legenda");

        var avaliacao = modelBuilder.Entity<Avaliacao>();
        avaliacao.HasBaseType((Type?)null);
        avaliacao.ToTable("nps");
        avaliacao.HasKey(a => a.Id);
        avaliacao.Property(a => a.Id).HasColumnName("id_nps");
        avaliacao.Property(a => a.UsuarioId).HasColumnName("id_cliente");
        avaliacao.Property(a => a.RestauranteId).HasColumnName("id_estabelecimento");
        avaliacao.Property(a => a.Nota).HasColumnName("nps_geral");
        avaliacao.Property(a => a.NpsNota).HasColumnName("nps_nota");
        avaliacao.Property(a => a.Comentario).HasColumnName("comentario");
        avaliacao.Property(a => a.DataAvaliacao).HasColumnName("data_avaliacao");
        avaliacao.HasOne(a => a.Usuario).WithMany().HasForeignKey(a => a.UsuarioId);

        var perfilCliente = modelBuilder.Entity<PerfilCliente>();
        perfilCliente.ToTable("buillon_app_perfil");
        perfilCliente.HasKey(p => p.UsuarioId);
        perfilCliente.Property(p => p.UsuarioId).HasColumnName("id_cliente");
        perfilCliente.Property(p => p.Bio).HasColumnName("bio").HasMaxLength(160);
        perfilCliente.Property(p => p.Avatar).HasColumnName("avatar").HasMaxLength(255);
        var perfilFornecedor = modelBuilder.Entity<PerfilFornecedor>();
        perfilFornecedor.ToTable("fornecedor_perfil");
        perfilFornecedor.HasKey(p => p.FornecedorId);
        perfilFornecedor.Property(p => p.FornecedorId).HasColumnName("id_fornecedor");
        perfilFornecedor.Property(p => p.Bio).HasColumnName("bio").HasMaxLength(160);
        perfilFornecedor.Property(p => p.Avatar).HasColumnName("avatar").HasMaxLength(255);

        var favoritoCliente = modelBuilder.Entity<FavoritoCliente>();
        favoritoCliente.ToTable("buillon_app_favorito");
        favoritoCliente.HasKey(f => new { f.UsuarioId, f.RestauranteId });
        favoritoCliente.Property(f => f.UsuarioId).HasColumnName("id_cliente");
        favoritoCliente.Property(f => f.RestauranteId).HasColumnName("id_estabelecimento");
        favoritoCliente.HasOne<Usuario>().WithMany().HasForeignKey(f => f.UsuarioId);
        favoritoCliente.HasOne<Restaurante>().WithMany().HasForeignKey(f => f.RestauranteId);
        var favoritoFornecedor = modelBuilder.Entity<FavoritoFornecedor>();
        favoritoFornecedor.ToTable("fornecedor_favorito");
        favoritoFornecedor.HasKey(f => new { f.FornecedorId, f.RestauranteId });
        favoritoFornecedor.Property(f => f.FornecedorId).HasColumnName("id_fornecedor");
        favoritoFornecedor.Property(f => f.RestauranteId).HasColumnName("id_estabelecimento");
        favoritoFornecedor.HasOne<Fornecedor>().WithMany().HasForeignKey(f => f.FornecedorId);
        favoritoFornecedor.HasOne<Restaurante>().WithMany().HasForeignKey(f => f.RestauranteId);

        var imagem = modelBuilder.Entity<ArquivoImagem>();
        imagem.ToTable("estabelecimento_imagem");
        imagem.HasKey(i => i.Id);
        imagem.Property(i => i.Id).HasColumnName("id").ValueGeneratedNever();
        imagem.Property(i => i.RestauranteId).HasColumnName("id_estabelecimento");
        imagem.Property(i => i.Tipo).HasColumnName("tipo").HasMaxLength(20);
        imagem.Property(i => i.Dados).HasColumnName("dados");
        imagem.HasOne<Restaurante>().WithMany().HasForeignKey(i => i.RestauranteId);
        var publicacao = modelBuilder.Entity<PublicacaoEstabelecimento>();
        publicacao.ToTable("estabelecimento_publicacao");
        publicacao.HasKey(p => p.Id);
        publicacao.Property(p => p.Id).HasColumnName("id");
        publicacao.Property(p => p.RestauranteId).HasColumnName("id_estabelecimento");
        publicacao.Property(p => p.Comentario).HasColumnName("comentario").HasMaxLength(1000);
        publicacao.Property(p => p.CriadoEm).HasColumnName("criado_em");

        // As tabelas já existem: a aplicação não chama EnsureCreated nem Migrate.
        // Média e ranking são calculados por consulta; as triggers citadas no texto
        // original não existem no scriptPIM.sql enviado.
    }
}

# Como o código funciona

`lib/main.dart` inicia o Flutter. `lib/src/app.dart` monta a navegação e injeta o repositório no `AppController`. As telas ficam em `lib/src/ui/`, os modelos em `lib/src/domain/` e os dois repositórios em `lib/src/data/`.

No modo demonstração, o repositório guarda os dados em memória. No modo integrado, o fluxo passa pela API C#:

```text
Tela Flutter → AppController → HttpBuillonRepository → Controllers → Negocio → Repositorio → Supabase PostgreSQL
```

- **Controllers** recebem as chamadas HTTP e verificam o tipo de conta nas rotas protegidas.
- **Modelos** contêm as entidades com herança e validação, além dos DTOs que definem o JSON devolvido ao Flutter.
- **Negocio** valida cadastros, sessões, estabelecimentos e avaliações.
- **Repositorio** implementa IUsuarioRepositorio e IRestauranteRepositorio com Entity Framework Core, Include, LINQ e SaveChangesAsync. O BuillonContext mapeia as entidades às tabelas existentes. O ranking e as operações específicas de PostgreSQL usam consultas parametrizadas pelo Entity Framework.
- **supabase/migrations** contém o esquema do Buillon. **database** contém os arquivos do SQL Server usados como referência.

Na edição de uma avaliação, o controlador incorpora o registro retornado pela API. Favoritos e perfil também atualizam a tela após a confirmação da gravação. O aplicativo consulta o ranking depois de mudanças nas avaliações e usa o cálculo local se a consulta estiver indisponível.

Para configurar o Supabase, iniciar a API e conectar o Flutter, siga o [guia de integração](INTEGRACAO.md).

A autenticação usa JWT assinado, com validade de oito horas. A chave e os identificadores de sessões encerradas são preservados na pasta privada `backend/.local/`. Veja a comparação com o material original e o roteiro em [Apresentação do projeto](APRESENTACAO.md).

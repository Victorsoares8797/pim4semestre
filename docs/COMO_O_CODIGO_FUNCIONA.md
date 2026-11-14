# Como o código funciona

`lib/main.dart` inicia o Flutter. `lib/src/app.dart` monta a navegação e injeta o repositório no `AppController`. As telas ficam em `lib/src/ui/`, os modelos em `lib/src/domain/` e os dois repositórios em `lib/src/data/`.

No modo demonstração, o repositório guarda os dados em memória. No modo integrado, o fluxo passa pela API C#:

```text
Tela Flutter → AppController → HttpBuillonRepository → Controllers → Negocio → Repositorio → Supabase PostgreSQL
```

- **Controllers** recebem as chamadas HTTP e verificam o tipo de conta nas rotas protegidas.
- **Modelos** definem os contratos JSON e as projeções que a API devolve ao Flutter.
- **Negocio** valida cadastros, sessões, estabelecimentos e avaliações.
- **Repositorio** usa Npgsql, consultas parametrizadas e a função de ranking do PostgreSQL.
- **supabase/migrations** contém o esquema do Buillon. **database** contém os arquivos do SQL Server usados como referência.

Na edição de uma avaliação, o controlador incorpora o registro retornado pela API. Favoritos e perfil também atualizam a tela após a confirmação da gravação. O aplicativo consulta o ranking depois de mudanças nas avaliações e usa o cálculo local se a consulta estiver indisponível.

Para configurar o Supabase, iniciar a API e conectar o Flutter, siga o [guia de integração](INTEGRACAO.md).

# Buillon com Supabase

O site HTML e o aplicativo Flutter usam a API ASP.NET Core em `backend/`. A API usa Npgsql para ler e gravar no esquema privado `buillon` do PostgreSQL. O site usa a API no próprio domínio para cadastro, login e sessão. A conexão PostgreSQL fica no servidor.

## 1. Preparar o esquema

As migrações em `supabase/migrations/` criam o esquema PostgreSQL, a função de ranking e o catálogo de exemplo. Execute os arquivos em ordem de nome no SQL Editor de um novo projeto Supabase. O arquivo [scriptPIM.sql](../database/scriptPIM.sql) contém o esquema histórico em T-SQL. O projeto hospedado [pim4semestre](https://supabase.com/dashboard/project/opjxuwjokbuzucvqogrl) já usa o esquema PostgreSQL.

## 2. Iniciar a API

Na Área de Trabalho, abra **Configurar Supabase** e digite a senha PostgreSQL do projeto. Na raiz do projeto, o mesmo configurador pode ser iniciado com:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\configurar-supabase.ps1
dotnet run --project backend/Buillon.Api.csproj --urls http://localhost:5080
```

O mesmo servidor abre o site HTML em `http://localhost:5080`. O comando `./iniciar-site.ps1` inicia o site e a API na mesma porta.

O configurador usa o Session pooler, valida o servidor com o certificado oficial e grava `ConnectionStrings.Supabase` em `backend/appsettings.Local.json`. Esse arquivo fica fora do pacote de distribuição. Em outro ambiente, defina `ConnectionStrings__Supabase` no processo da API com os dados mostrados em **Connect** e o certificado do projeto.

Para verificar a conexão, execute `Invoke-RestMethod http://localhost:5080/api/health`. O resultado esperado é `status = ok`.
## 3. Abrir o Flutter integrado

Em outro terminal, na raiz do projeto:

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=BUILLON_API_URL=http://localhost:5080
```

Também é possível executar `.\iniciar.ps1`. O script usa `http://localhost:5080` por padrão. Se a aplicação web usar outra origem, defina `Buillon__OrigensWeb` antes de iniciar a API, com as origens separadas por vírgula.

No modo integrado, contas **CPF** e **CNPJ** podem explorar o catálogo, consultar o Top 10, salvar favoritos e editar o perfil. Somente contas CPF podem publicar, editar ou excluir avaliações. A aba **Painel** aparece para contas CNPJ e permite cadastrar estabelecimentos e publicar fotos, pratos e comentários. As fotos escolhidas no aparelho são gravadas no PostgreSQL, com limite de 5 MB por imagem e suporte a JPG, PNG e WebP.

Em **Explorar**, as duas contas veem os estabelecimentos cadastrados e os 12 restaurantes fictícios identificados como **Exemplo**. As fotos dos exemplos usam os arquivos incluídos no Flutter. As avaliações fictícias ficam na demonstração.

## Uso da API

| Método e caminho | Dados ou acesso |
| --- | --- |
| `POST /api/auth/registar` | `nome`, `email`, `senha` e `cpf` para cliente. Para fornecedor, use `role: "Proprietario"` e `documento` com CNPJ. |
| `POST /api/auth/login` | `email`, `senha`, `documento` e `role`. O papel padrão é `Cliente`. Clientes antigos da API também podem entrar com e-mail e senha. |
| `POST /api/auth/sair` | Encerra a sessão identificada pelo token. |
| `GET /api/restaurantes` | Catálogo. Aceita `cidade`, `bairro`, `pagina` e `tamanho` de 1 a 50. |
| `GET /api/restaurantes/{id}` e `GET /api/restaurantes/categorias` | Detalhe do estabelecimento e lista de categorias. |
| `GET /api/restaurantes/ranking` | Resultado de `buillon.ranking_estabelecimentos()`. |
| `GET /api/restaurantes/avaliacoes` | Sessão autenticada. Avaliações com nota de 1 a 5. |
| `PUT /api/restaurantes/{id}/avaliacao` | Cliente. `rating`, `comment` e `npsNota` opcional de 0 a 10. |
| `DELETE /api/restaurantes/avaliacoes/{id}` | Cliente. Exclui a própria avaliação. O ID é o da avaliação. |
| `PUT /api/perfil` | Cliente ou proprietário. `name`, `bio` e `avatar` escolhido entre as três imagens incluídas ou vazio. |
| `GET /api/perfil/favoritos` e `PUT /api/perfil/favoritos/{id}` | Cliente ou proprietário. Para definir, envie `{"favorite": true}` ou `{"favorite": false}`. |
| `POST /api/restaurantes` e `PUT /api/restaurantes/{id}` | Proprietário. Nome, categoria e campos de endereço. Na edição, o restaurante deve pertencer ao fornecedor autenticado. |
| `GET /api/restaurantes/meus` | Proprietário. Lista os estabelecimentos vinculados à conta. |
| `POST /api/restaurantes/{id}/cardapio` | Proprietário. `nome`, `descricao`, `preco` e `arquivo` em Base64 ou `imagem` HTTPS opcional. |
| `POST /api/restaurantes/{id}/fotos` | Proprietário. `arquivo` em Base64 ou `url` HTTPS, com `legenda` opcional. |
| `POST /api/restaurantes/{id}/publicacoes` | Proprietário. Publica `comentario` na página do estabelecimento. |

As rotas autenticadas recebem `Authorization: Bearer <token>`. Cadastro e login retornam o token e o perfil. A sessão dura até oito horas no processo da API. A senha de uma nova conta é gravada como hash com salt pelo `PasswordHasher` do ASP.NET Core. Contas antigas com outro formato de senha precisam ser migradas.

### Criar o primeiro restaurante

Use dados fictícios em um ambiente de teste. Primeiro, insira uma categoria no SQL Editor com `insert into buillon.categoria (nome_categoria) values ('Brasileira');`. Em seguida, este exemplo registra um fornecedor e cadastra um restaurante:

```powershell
$api = 'http://localhost:5080/api'
$fornecedor = @{
    nome = 'Fornecedor de Teste'; email = 'fornecedor@example.com'
    senha = 'senha-local-teste'; role = 'Proprietario'; documento = '12345678000199'
} | ConvertTo-Json
$sessao = Invoke-RestMethod "$api/auth/registar" -Method Post -ContentType 'application/json' -Body $fornecedor
$categoria = (Invoke-RestMethod "$api/restaurantes/categorias" | Select-Object -First 1).id
$restaurante = @{
    nome = 'Restaurante de Teste'; descricao = 'Cozinha brasileira'
    categoriaId = $categoria; cnpj = '12345678000199'
    rua = 'Rua de Teste'; numero = '10'; bairro = 'Centro'; cidade = 'Sao Paulo'; estado = 'SP'
} | ConvertTo-Json
Invoke-RestMethod "$api/restaurantes" -Method Post -ContentType 'application/json' -Body $restaurante `
    -Headers @{ Authorization = "Bearer $($sessao.token)" }
```

## Mapeamentos

- Clientes usam `CLIENTE`. Proprietários usam `FORNECEDOR` e só podem alterar estabelecimentos ligados ao próprio `ID_FORNECEDOR`.
- O catálogo usa `ESTABELECIMENTO`, `CATEGORIA` e `ENDERECO`. Quando há vários endereços, o app exibe o de menor ID. Horário e faixa de preço aparecem quando estão preenchidos. Os pratos do catálogo de exemplo podem aparecer sem preço.
- As estrelas do Flutter são gravadas em `NPS_GERAL`. A nota `NPS_NOTA` é opcional na API e é preservada quando a edição informa apenas as estrelas. Os novos registros de avaliação recebem data em UTC.
- O cliente Flutter reúne as páginas do catálogo para manter a busca e os filtros atuais. O Top 10 usa a ordem retornada pelo PostgreSQL e pode ser calculado localmente durante uma falha isolada da rota de ranking.


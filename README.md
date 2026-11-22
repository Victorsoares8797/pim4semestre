# Buillon · À sua mesa

Aplicativo Flutter de descoberta e avaliação de restaurantes, construído a partir do projeto `pim4semestre.zip`. Mantém o nome Buillon, o logotipo e os projetos de plataforma da base original.

## Funcionalidades

- Login e cadastro com CPF para clientes e CNPJ para estabelecimentos no modo integrado.
- Painel de estabelecimentos para cadastrar e editar dados, escolher fotos do aparelho, publicar pratos e comentários e acompanhar avaliações de clientes.
- As contas CPF e CNPJ podem explorar, consultar o Top 10, favoritar e editar o perfil. A avaliação de restaurantes é exclusiva de contas CPF. A gestão de estabelecimentos é exclusiva de contas CNPJ.
- Entrada na demonstração sem credenciais.
- Exploração com fotos, médias calculadas, busca por nome/cozinha/bairro, filtros e ordenação.
- Detalhes do restaurante: foto, endereço, horário, pratos com galeria, distribuição de notas e comentários.
- Avaliação de 1 a 5 estrelas com comentário; edição e exclusão da própria avaliação.
- Favoritos por usuário, disponíveis em uma aba própria e no perfil.
- Perfil com foto, nome, bio, estatísticas, melhores restaurantes avaliados e comentários.
- Edição de nome, bio e escolha entre três fotos incluídas na demonstração.
- Top 10 dinâmico a partir das avaliações. No modo integrado, a ordenação vem da função PostgreSQL do Supabase.
- Interface projetada para celulares, com navegação inferior, lista em coluna e avaliação adaptada ao teclado.

## Abrir o site

O site original do PIM 3 está em `site-pim3/`, em HTML, CSS e JavaScript. Os formulários usam a API do aplicativo para cadastro e login de clientes por CPF e de estabelecimentos por CNPJ. As contas são compartilhadas pelo Supabase.

```powershell
.\iniciar-site.ps1
```

Abra `http://localhost:5080` no navegador. O script sobe o site e a API juntos. É preciso ter o .NET 10 e uma conexão do Supabase configurada no servidor. Consulte a [configuração do banco e da API](docs/INTEGRACAO.md).

## Executar o aplicativo em desenvolvimento

Use Flutter com Dart 3.11 ou superior. A versão usada para validar o projeto foi Flutter 3.47.9 com Dart 3.13.7.

```powershell
.\iniciar.ps1
```

O app usa a API local na porta 5080. A configuração **Buillon no Chrome** do VS Code também abre o modo integrado. Em **Cadastre-se**, escolha **CPF** para acessar a área de clientes ou **CNPJ** para acessar o painel de estabelecimentos. Para indicar um SDK fora do PATH, passe `-FlutterPath` com o caminho de `flutter.bat`.

Para explorar os dados fictícios em memória, execute `.\iniciar.ps1 -Demo` e escolha **Explorar demonstração**.

## Dados e integração

O Flutter chama a API .NET 10, que usa o PostgreSQL do Supabase. Configure a conexão com `configurar-supabase.ps1`. Para usar outro endereço de API, passe `-ApiUrl` ao script ou `--dart-define=BUILLON_API_URL=...` ao Flutter. [Configuração do banco e da API](docs/INTEGRACAO.md)

Os 12 restaurantes fictícios da demonstração também aparecem em **Explorar** no modo integrado, identificados como **Exemplo**. As avaliações fictícias ficam na demonstração. As fotografias ilustrativas ficam em `assets/images/`. Créditos em [assets/CREDITS.md](assets/CREDITS.md). As fontes Manrope e Lora incluem suas licenças OFL em `assets/fonts/`.

Para entender o projeto passo a passo, leia [Como o código funciona](docs/COMO_O_CODIGO_FUNCIONA.md). A [comparação com o código original e o roteiro de apresentação](docs/APRESENTACAO.md) explicam as adaptações para o Supabase.

## Organização

```text
lib/
  main.dart                         entrada original preservada
  TelaCadastrese.dart                exportação de compatibilidade
  src/
    app.dart                        composição e injeção do repositório
    application/app_controller.dart estado e ações da aplicação
    domain/                         modelos, contrato e cálculo de ranking
    data/                           repositórios em memória e HTTP
    ui/                             telas, componentes e tema
backend/
  Controllers/                      rotas ASP.NET Core e autorização JWT
  Modelos/                          entidades, validações e contratos JSON
  Negocio/                          validação, autenticação e sessões
  Repositorio/                      interfaces e Entity Framework para PostgreSQL
database/                           scripts originais do SQL Server
supabase/migrations/                esquema PostgreSQL do Buillon
```

## Verificar e compilar

```powershell
flutter analyze
flutter test --reporter expanded
flutter build web --release --no-web-resources-cdn
flutter build apk --debug
dotnet build backend/Buillon.Api.csproj
dotnet test backend.Tests/Buillon.Api.Tests.csproj
```

Os testes cobrem médias, desempate e limite do ranking, JSON, cadastro, login, isolamento de favoritos, permissões sobre avaliações, validações, atualização de perfil e navegação responsiva. `test/visual_test.dart` também salva capturas reais em `docs/screenshots/`.

A compilação web do aplicativo fica em `build/web/`. Para gerar uma publicação do site HTML com a API no mesmo servidor:

```powershell
dotnet publish backend/Buillon.Api.csproj -c Release -o build/site-pim3-publicado
```

Configure `ConnectionStrings__Supabase` no servidor e execute `dotnet Buillon.Api.dll` dentro de `build/site-pim3-publicado`. Use HTTPS na hospedagem.

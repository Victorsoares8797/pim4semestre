# Validação mobile

Interface projetada para celulares Android e iOS. Navegação inferior, lista de restaurantes em uma coluna e formulário de avaliação adaptado ao teclado.

A análise Flutter passou sem problemas. Os testes de lógica, cadastro, login, avaliações, favoritos e navegação passaram em tamanhos de 320×720 a 430×932. As capturas reais das telas de celular estão em `screenshots/mobile/`. O APK é uma compilação de demonstração e não foi executado em dispositivo físico nesta sessão.

As capturas foram feitas no modo demonstração, com dados em memória. A configuração do modo integrado está em [INTEGRACAO.md](INTEGRACAO.md).

## Validação anterior com Supabase

- O painel de estabelecimentos foi verificado com registros temporários no Supabase. O teste confirmou a autenticação por CPF e CNPJ, a edição dos dados, o envio e a leitura de arquivos de imagem distintos, a publicação de comentários e a separação das permissões entre cliente e proprietário.

- O esquema `buillon` foi aplicado pelo SQL Editor do projeto `pim4semestre`. A consulta de confirmação encontrou as dez tabelas e executou a função de ranking.
- A API autenticou no PostgreSQL remoto com validação do certificado. O endpoint `/api/health` retornou `ok`, e as rotas do catálogo e do ranking retornaram HTTP 200 com listas vazias.
- Os testes com gravação foram executados em um PostgreSQL temporário, incluindo cadastro, login, permissões, alterações de catálogo, avaliações simultâneas, perfil e favoritos. A análise estática e os 20 testes Flutter de lógica e interface executados passaram.

## Validação anterior com SQL Server

- A análise Flutter terminou sem apontamentos e os 21 testes passaram, incluindo dois casos com respostas HTTP simuladas para cadastro, sessão, ranking e gravação de avaliação.
- A API compilou em .NET 10 e respondeu a chamadas reais de validação de CPF, autorização, CORS e diagnóstico de conexão.
- A compilação web com a URL da API foi concluída. O analisador T-SQL verificou os scripts e as consultas do repositório.
- A validação de ponta a ponta foi concluída no SQL Server 2025 Express, na instância local `.\SQLEXPRESS`. O `scriptPIM.sql` foi executado com o SHA-256 original e o banco `BUILLON` ficou online com nível de compatibilidade 170.
- As chamadas reais à API confirmaram cadastro, login, permissões de proprietário, catálogo, cardápio, fotos, gravação e edição de avaliações, ranking pela procedure, persistência de perfil e favoritos e encerramento da sessão. Os registros temporários foram removidos ao final.

## Validação da API próxima do código original

Verificação de 22 de novembro de 2026, após a retomada do Entity Framework Core e do JWT:

- A análise Flutter não apontou problemas e os 23 testes do aplicativo passaram.
- Os nove testes .NET passaram, sem testes ignorados. Eles verificam o JWT e o SQL original e executam o fluxo HTTP da API com Entity Framework em PostgreSQL 17 temporário, usando as quatro migrações do projeto.
- O fluxo integrado confirmou cadastro e login CPF/CNPJ, duplicidade de conta, autorização do proprietário, cadastro e edição de restaurante, endereços, fotos com leitura dos bytes enviados, pratos, publicações, favoritos, perfil e logout.
- Quatro edições simultâneas da mesma avaliação produziram um único registro. A edição preservou a nota NPS opcional, e o ranking e a propriedade NotaMedia retornaram a média esperada.
- A assinatura, a validade, o emissor e o público do JWT foram verificados. Alterar o perfil no payload invalidou o token. A chave persistida manteve logins válidos após reiniciar; o logout persistido manteve a sessão encerrada.
- A sessão do site por cookie e a especificação OpenAPI foram verificadas na API de teste.
- O banco temporário foi removido pela fixture ao terminar. Nenhuma migração ou gravação de teste foi aplicada ao Supabase nesta reorganização.
- O projeto Supabase estava pausado e foi reativado. Na API conectada ao projeto, health, categorias, catálogo e ranking retornaram HTTP 200. O catálogo tinha 13 estabelecimentos nessa consulta.
- A publicação Release da API com o site HTML foi concluída. A conferência dos arquivos publicados não encontrou appsettings.Local.json, a pasta .local ou a chave JWT.
- O SQL original e a cópia do código C# de referência tiveram os hashes comparados com os arquivos enviados e permaneceram idênticos.

O roteiro de apresentação e a comparação com a referência estão em [APRESENTACAO.md](APRESENTACAO.md). As instruções dos testes estão em [backend.Tests/README.md](../backend.Tests/README.md).

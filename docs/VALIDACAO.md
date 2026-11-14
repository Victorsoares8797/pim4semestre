# Validação mobile

Interface projetada para celulares Android e iOS. Navegação inferior, lista de restaurantes em uma coluna e formulário de avaliação adaptado ao teclado.

A análise Flutter passou sem problemas. Os testes de lógica, cadastro, login, avaliações, favoritos e navegação passaram em tamanhos de 320×720 a 430×932. As capturas reais das telas de celular estão em `screenshots/mobile/`. O APK é uma compilação de demonstração e não foi executado em dispositivo físico nesta sessão.

As capturas foram feitas no modo demonstração, com dados em memória. A configuração do modo integrado está em [INTEGRACAO.md](INTEGRACAO.md).

## Validação com Supabase

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

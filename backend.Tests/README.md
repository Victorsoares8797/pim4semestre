# Testes da API Buillon

Os testes de JWT verificam assinatura, validade, emissor, público, permissões, persistência da chave e revogação após reiniciar. Também há uma verificação do SHA-256 do SQL original.

```powershell
dotnet test backend.Tests/Buillon.Api.Tests.csproj
```

O teste de integração usa a API real com Entity Framework e PostgreSQL. Cria um banco com nome aleatório, aplica as quatro migrações, executa os fluxos e remove apenas esse banco ao terminar. Ele só aceita PostgreSQL local; nunca usa a conexão do Supabase para gravar.

Para executá-lo, disponibilize uma instância local de PostgreSQL com um usuário que possa criar bancos e defina a conexão administrativa apenas no processo:

```powershell
$env:BUILLON_TEST_ADMIN = 'Host=127.0.0.1;Port=5432;Database=postgres;Username=seu_usuario;Password=sua_senha'
dotnet test backend.Tests/Buillon.Api.Tests.csproj
Remove-Item Env:BUILLON_TEST_ADMIN
```

Sem essa variável, o teste de integração é identificado como ignorado. As credenciais acima são marcadores para configuração, não contas incluídas no projeto.

O fluxo integrado verifica cadastro e login CPF/CNPJ, duplicidade de conta, autorização do proprietário, criação e edição de estabelecimento, filtros do catálogo, cardápio, fotos, publicações, avaliações simultâneas, preservação do NPS, ranking, favoritos, perfil, logout, sessão do site por cookie e documentação OpenAPI.

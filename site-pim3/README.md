Buillon - Plataforma de Avaliação de Restaurantes

Este projeto consiste em uma plataforma web desenvolvida para ajudar usuários a escolherem e avaliarem restaurantes. O objetivo principal é criar uma comunidade onde as pessoas possam compartilhar suas experiências gastronômicas e descobrir novos lugares para visitar.

## Abrir o site

Na raiz do projeto, execute `./iniciar-site.ps1` e abra `http://localhost:5080`. A API ASP.NET Core usa a conexão Supabase do aplicativo. Consulte [a configuração](../docs/INTEGRACAO.md).

Em **Login**, escolha **Cliente (CPF)** ou **Estabelecimento (CNPJ)** e informe o documento, o e-mail e a senha. Em **Crie sua conta**, o cadastro pede também o nome e a confirmação da senha. Use **Minha conta** para conferir o tipo da conta ou sair.

Os formulários funcionam quando as páginas são servidas pela API no mesmo endereço. As páginas públicas são HTML e usam o CSS e as imagens do site original.

Tecnologias Utilizadas
* HTML5
* CSS3
* JavaScript

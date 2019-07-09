# language: pt

Funcionalidade: Login e logout

  Cenário: Login com informações inválidas
    Dado que acesso a página de login
    Quando informo dados inválidos para login
    Então não conseguirei acessar o sistema

  Cenário: Login usando o email
    Dado que acesso a página de login
    Quando informo o email para login
    Então serei logado no sistema

  Cenário: Login usando o usuário
    Dado que acesso a página de login
    Quando informo o usuário para login
    Então serei logado no sistema

  Cenário: Login usando o cpf
    Dado que acesso a página de login
    Quando informo o cpf para login
    Então serei logado no sistema

  Cenário: Login usando o cpf sem caracteres não numéricos
    Dado que acesso a página de login
    Quando informo o cpf sem caracteres não numéricos para login
    Então serei logado no sistema

  Cenário: Logout
    Dado que estou logado
    Então poderei sair do sistema

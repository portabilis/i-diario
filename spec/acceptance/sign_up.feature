# language: pt

Funcionalidade: Cadastro de usuário

  Cenário: Realizar cadastro de pais
    Dado que acesso a página de signup
    Quando informo os dados para o cadastro de pais
    Então deverei ser logado ao sistema

  Cenário: Solicitar acesso de aluno
    Dado que acesso a página de signup
    Quando informo os dados para o acesso do aluno
    Então deverei ver a mensagem de acesso solicitado
    E o login não poderá ser realizado enquanto o acesso estiver pendente

  Cenário: Solicitar acesso de servidor
    Dado que acesso a página de signup
    Quando informo os dados para o acesso do servidor
    Então deverei ver a mensagem de acesso solicitado
    E o servidor não poderá logar enquanto o acesso estiver pendente

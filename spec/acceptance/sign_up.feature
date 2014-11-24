# language: pt

Funcionalidade: Cadastro de usuário

  Cenário: Realizar cadastro de pais
    Dado que acesso a página de signup de pais
    Quando informo os dados para o cadastro de pais
    Então deverei ser logado ao sistema

  Cenário: Solicitar acesso de aluno
    Dado que acesso a página de signup de alunos
    Quando informo os dados para o acesso do aluno
    Então deverei ver a mensagem de acesso solicitado
    E o login não poderá ser realizado enquanto o acesso estiver pendente

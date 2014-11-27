# language: pt

Funcionalidade: Gerenciamento de usuários

  Contexto:
    Dado que estou logado

  Cenário: Liberação de usuários
    Dado que existem usuários com acesso pendente
    E que acesso a listagem de usuários
    Quando eu entrar no formulário de um usuário pendente
    Então poderei liberar o acesso deste usuário

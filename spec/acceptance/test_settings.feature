# language: pt

Funcionalidade: Configurações de avaliação

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar uma configuração de avaliação
    Dado que acesso a listagem de configuração de avaliação
    Quando eu entrar no formulário de nova configuração de avaliação
    Então poderei cadastrar uma nova configuração de avaliação

  Cenário: Editar uma configuração de avaliação
    Dado que existe uma configuração de avaliação cadastrada
    Quando entro na tela de edição desta configuração de avaliação
    Então poderei alterar os dados desta configuração de avaliação

  Cenário: Excluir uma configuração de avaliação
    Dado que existe uma configuração de avaliação cadastrada
    Então poderei excluir uma configuração de avaliação

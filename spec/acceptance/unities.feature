# language: pt

Funcionalidade: Gerenciamento de unidades

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar uma unidade
    Dado que acesso a listagem de unidades
    Quando eu entrar no formulário de nova unidade
    Então poderei cadastrar uma nova unidade

  Cenário: Editar uma unidade
    Dado que existe uma unidade cadastrada
    Quando entro na tela de edição desta unidade
    Então poderei alterar seus dados

  Cenário: Excluir uma unidade
    Dado que existe uma unidade cadastrada
    Então poderei excluir esta unidade

# language: pt

Funcionalidade: Gerenciamento de permissões

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar uma permissão
    Dado que acesso a listagem de permissões
    Quando eu entrar no formulário de nova permissão
    Então poderei cadastrar uma nova permissão

  Cenário: Editar uma permissão
    Dado que existe uma permissão cadastrada
    Quando entro na tela de edição desta permissão
    Então poderei permitir acesso às funcionalidades

  Cenário: Excluir uma permissão
    Dado que existem permissões cadastradas
    Então poderei excluir uma permissão

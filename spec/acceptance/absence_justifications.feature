# language: pt

Funcionalidade: Justificativas de falta

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar uma justificativa de falta
    Dado que acesso a listagem de justificativas de faltas
    Quando eu entrar no formulário de nova justificativa de falta
    Então poderei cadastrar uma nova justificativa de falta

  Cenário: Editar uma justificativa de falta
    Dado que existe uma justificativa de falta cadastrada
    Quando entro na tela de edição desta justificativa de falta
    Então poderei alterar os dados desta justificativa de falta

  Cenário: Excluir uma justificativa de falta
    Dado que existe uma justificativa de falta cadastrada
    Então poderei excluir uma justificativa de falta

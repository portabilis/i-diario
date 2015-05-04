# language: pt

Funcionalidade: Eventos do calendário letivo

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar um evento do calendário letivo
    Dado que acesso a listagem de eventos do calendário letivo
    Quando eu entrar no formulário de novo evento do calendário letivo
    Então poderei cadastrar um novo evento do calendário letivo

  Cenário: Editar um evento do calendário letivo
    Dado que existe um evento do calendário letivo cadastrada
    Quando entro na tela de edição deste evento do calendário letivo
    Então poderei alterar os dados deste evento do calendário letivo

  Cenário: Excluir um evento do calendário letivo
    Dado que existe um evento do calendário letivo cadastrada
    Então poderei excluir um evento do calendário letivo

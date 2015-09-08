# language: pt

Funcionalidade: Calendários letivo

  Contexto:
    Dado que estou logado

  Cenário: Sincronizar novos calendários letivos do i-Educar
    Dado que acesso a listagem de celendários letivos
    Quando eu clicar em Sincronizar
    Então poderei sincronizar novos calendários letivos do i-Educar

  # Cenário: Cadastrar um calendário letivo
  #   Dado que acesso a listagem de calendário letivo
  #   Quando eu entrar no formulário de novo calendário letivo
  #   Então poderei cadastrar um novo calendário letivo

  Cenário: Editar um calendário letivo
    Dado que existe um calendário letivo cadastrada
    Quando entro na tela de edição deste calendário letivo
    Então poderei alterar os dados deste calendário letivo

  Cenário: Excluir um calendário letivo
    Dado que existe um calendário letivo cadastrada
    Então poderei excluir um calendário letivo

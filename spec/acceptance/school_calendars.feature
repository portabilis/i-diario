# language: pt

Funcionalidade: Calendários letivo

  Contexto:
    Dado que estou logado

  # TODO: Test randomly failing, need to find a solution

  # Cenário: Sincronizar novos calendários letivos do i-Educar
  #   Dado que as unidades estão sincronizadas com o i-Educar
  #   E que acesso a listagem de calendários letivos
  #   Quando eu clicar em Sincronizar
  #   Então poderei sincronizar novos calendários letivos do i-Educar

  Cenário: Editar um calendário letivo
    Dado que existe um calendário letivo cadastrada
    Quando entro na tela de edição deste calendário letivo
    Então poderei alterar os dados deste calendário letivo

  Cenário: Excluir um calendário letivo
    Dado que existe um calendário letivo cadastrada
    Então poderei excluir um calendário letivo

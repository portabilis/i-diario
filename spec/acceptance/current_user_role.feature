# language: pt

Funcionalidade: Perfil atual

  Cenário: Alterar perfil atual
    Dado que possuo múltiplos perfis
    E que estou logado
    Quando eu alterar o meu perfil atual
    Então irei visualizar uma mensagem de perfil atual alterado com sucesso
    E estarei logado com outro perfil

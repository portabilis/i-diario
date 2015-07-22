# language: pt

Funcionalidade: Gerenciamento de avaliações

  Contexto:
    Dado que estou logado
    E que existem turmas com tipo de avaliação não numérica vinculadas ao professor logado

  Cenário: Cadastrar uma avaliação para uma turma com tipo de avaliação não numérica
    Dado que acesso a listagem de avaliações
    Quando eu entrar no formulário de nova avaliação
    E selecionar uma turma com tipo de avaliação não numérica
    Então devo visualizar uma mensagem de turma com tipo de avaliação não numérica
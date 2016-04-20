# language: pt

Funcionalidade: Diário de observações

  Contexto:
    Dado que estou logado e conectado a uma escola
    E que dou aula para uma turma com frequência por disciplina

  Cenário: Cadastrar um registro no diário de observações
    Dado que acesso a listagem do diário de observações
    Quando eu entrar no formulário de novo registro do diário de observações
    Então poderei cadastrar um novo registro no diário de observações

  Cenário: Editar um registro no diário de observações
    Dado que existe um registro do diário de observações cadastrado
    Quando eu entro na tela de edição deste registro do diário de observações
    Então poderei atualizar os dados deste registro do diário de observações

  Cenário: Excluir um registro no diário de observações
    Dado que existe um registro do diário de observações cadastrado
    Então poderei excluir este registro do diário de observações

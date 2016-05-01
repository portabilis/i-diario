# language: pt

Funcionalidade: Relatório de registro de observações

  Cenário: Imprimir um relatório de registro de observações
    Dado que estou logado e conectado a uma escola
    E que dou aula para uma turma com frequência por disciplina
    E que existe um registro do diário de observações cadastrado
    Quando eu entrar na tela do relatório de registro de observações
    Então poderei imprimir o relatório de registro de observações

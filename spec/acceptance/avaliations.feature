# language: pt

#Funcionalidade: Gerenciamento de avaliações

#  Contexto:
#    Dado que estou logado e conectado a uma escola

#  Cenário: Cadastrar uma avaliação quando configuração de avaliações com avaliações fixas e que não permitem desmembrar
#    Dado que existem turmas com tipo de avaliação númerica vinculadas ao professor logado
#    E que existe uma configuração de avaliação com avaliações fixas e que não permitem desmembrar
#    E que acesso a listagem de avaliações
#    Quando eu entrar no formulário de nova avaliação
#    E cadastrar uma nova avaliação com avaliações que não permite desmembrar
#    Então devo visualizar uma mensagem de avaliação cadastrada com sucesso

#  Cenário: Cadastrar uma avaliação quando configuração de avaliações com avaliações fixas e que permitem desmembrar
#    Dado que existem turmas com tipo de avaliação númerica vinculadas ao professor logado
#    E que existe uma configuração de avaliação com avaliações fixas e que permitem desmembrar
#    E que acesso a listagem de avaliações
#    E cadastrar uma nova avaliação com avaliações que permite desmembrar
#    Então devo visualizar uma mensagem de avaliação cadastrada com sucesso

#  Cenário: Cadastrar uma avaliação para uma turma com tipo de avaliação não numérica
#    Dado que existem turmas com tipo de avaliação não numérica vinculadas ao professor logado
#    E que existe uma configuração de avaliação com avaliações fixas e que não permitem desmembrar
#    E que acesso a listagem de avaliações
#    Quando eu entrar no formulário de nova avaliação
#    E selecionar uma turma com tipo de avaliação não numérica
#    Então devo visualizar uma mensagem de turma com tipo de avaliação não numérica

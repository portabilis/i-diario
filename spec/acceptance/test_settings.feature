# language: pt

Funcionalidade: Configurações de avaliação

  Contexto:
    Dado que estou logado

  Cenário: Cadastrar uma configuração de avaliação
    Dado que acesso a listagem de configuração de avaliação
    Quando eu entrar no formulário de nova configuração de avaliação
    Então poderei cadastrar uma nova configuração de avaliação

  Cenário: Editar uma configuração de avaliação
    Dado que existe uma configuração de avaliação cadastrada
    Quando entro na tela de edição desta configuração de avaliação
    Então poderei alterar os dados desta configuração de avaliação

  Cenário: Excluir uma configuração de avaliação
    Dado que existe uma configuração de avaliação cadastrada
    Então poderei excluir uma configuração de avaliação

  Cenário: Cadastrar uma avaliação com nota máxima 2, número de casas decimais 2 e fixar duas avaliações com peso 5,00 e sem tipo de avaliação
    Dado que acesso a listagem de configuração de avaliação
    Quando eu entrar no formulário de nova configuração de avaliação
    E cadastrar uma nova configuração de avaliação com nota máxima 2, número de casas decimais 2 e fixar duas avaliações com peso 5,00 e sem tipo de avaliação
    Então devo visualizar uma mensagem de tipo de avaliação não pode ficar em branco
    E devo visualizar os pesos das avaliações formatados corretamente


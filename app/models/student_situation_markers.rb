# Marcadores curtos exibidos nos relatórios (PDF) para indicar a situação do
# aluno em uma célula sem nota/frequência real. Fonte única consumida pelos relatórios
module StudentSituationMarkers
  NOT_ENROLLED = 'N'.freeze   # Aluno não enturmado
  EXEMPTED = 'D'.freeze       # Aluno dispensado da avaliação ou da disciplina
  ACTIVE_SEARCH = 'BA'.freeze # Aluno em busca ativa
  DEPENDENCE = 'DP'.freeze    # Aluno cursando dependência
  WITHOUT_NOTE = '-'.freeze   # Sem nota lançada (célula vazia de aluno enturmado)
end

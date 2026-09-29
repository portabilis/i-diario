module IeducarApi
  # Parecer descritivo da etapa em um componente (POST /api/v2/pareceres-por-etapa-e-componente).
  class PostOpinionsByStepAndDiscipline < PostOpinions
    POST_PATH = '/api/v2/pareceres-por-etapa-e-componente'.freeze
    LOG_PREFIX = '[pareceres-por-etapa-e-componente]'.freeze
    FIELDS = STUDENT_FIELDS.merge(componente_id: 'o componente curricular').freeze
    LOG_LABELS = STUDENT_LOG_LABELS.merge(componente_id: 'componente').freeze
  end
end

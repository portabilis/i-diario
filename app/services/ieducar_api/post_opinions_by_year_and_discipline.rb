module IeducarApi
  # Parecer descritivo do ano em um componente (POST /api/v2/pareceres-anual-por-componente). Não
  # tem etapa: o i-Educar grava o parecer como anual.
  class PostOpinionsByYearAndDiscipline < PostOpinions
    POST_PATH = '/api/v2/pareceres-anual-por-componente'.freeze
    LOG_PREFIX = '[pareceres-anual-por-componente]'.freeze
    FIELDS = STUDENT_FIELDS.except(:etapa).merge(componente_id: 'o componente curricular').freeze
    LOG_LABELS = STUDENT_LOG_LABELS.except(:etapa).merge(componente_id: 'componente').freeze
  end
end

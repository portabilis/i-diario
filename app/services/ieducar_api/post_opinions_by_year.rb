module IeducarApi
  # Parecer descritivo geral do ano (POST /api/v2/pareceres-anual-geral). Não tem etapa: o i-Educar
  # grava o parecer como anual.
  class PostOpinionsByYear < PostOpinions
    POST_PATH = '/api/v2/pareceres-anual-geral'.freeze
    LOG_PREFIX = '[pareceres-anual-geral]'.freeze
    FIELDS = STUDENT_FIELDS.except(:etapa).freeze
    LOG_LABELS = STUDENT_LOG_LABELS.except(:etapa).freeze
  end
end

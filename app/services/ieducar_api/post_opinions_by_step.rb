module IeducarApi
  # Parecer descritivo geral da etapa (POST /api/v2/pareceres-por-etapa-geral).
  class PostOpinionsByStep < PostOpinions
    POST_PATH = '/api/v2/pareceres-por-etapa-geral'.freeze
    LOG_PREFIX = '[pareceres-por-etapa-geral]'.freeze
    FIELDS = STUDENT_FIELDS
    LOG_LABELS = STUDENT_LOG_LABELS
  end
end

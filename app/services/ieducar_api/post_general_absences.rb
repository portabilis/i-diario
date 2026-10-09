module IeducarApi
  # Envia as faltas gerais de um aluno ao i-Educar (POST /api/v2/falta-geral).
  class PostGeneralAbsences < V2Base
    POST_PATH = '/api/v2/falta-geral'.freeze
    LOG_PREFIX = '[falta-geral]'.freeze
    SUCCESS_MESSAGE = 'Faltas postadas com sucesso!'.freeze
    FIELDS = STUDENT_FIELDS.merge(faltas: 'as faltas').freeze
    LOG_LABELS = STUDENT_LOG_LABELS.merge(faltas: 'faltas').freeze
  end
end

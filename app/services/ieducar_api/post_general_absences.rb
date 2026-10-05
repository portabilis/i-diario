module IeducarApi
  # Envia as faltas gerais de um aluno ao i-Educar (POST /api/v2/falta-geral).
  class PostGeneralAbsences < V2Base
    POST_PATH = '/api/v2/falta-geral'.freeze
    LOG_PREFIX = '[falta-geral]'.freeze
  end
end

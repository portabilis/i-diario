module IeducarApi
  # Envia as faltas gerais de um aluno ao i-Educar (POST /api/v2/falta-geral).
  #
  # i-Educar sem a versão atual do endpoint responde 200, com a mensagem do motivo, quando não há
  # matrícula elegível; V2Base trata esse caso como recusa de matrícula.
  class PostGeneralAbsences < V2Base
    POST_PATH = '/api/v2/falta-geral'.freeze
    LOG_PREFIX = '[falta-geral]'.freeze
  end
end

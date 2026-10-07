module IeducarApi
  # Envia a nota de um aluno em um componente curricular ao i-Educar (POST /api/v2/notas):
  # nota da etapa, com a recuperação da etapa quando houver, ou a recuperação final na etapa `Rc`.
  class PostScores < V2Base
    POST_PATH = '/api/v2/notas'.freeze
    LOG_PREFIX = '[notas]'.freeze
    SUCCESS_MESSAGE = 'Notas postadas com sucesso!'.freeze
    FINAL_RECOVERY_STEP = 'Rc'.freeze
    FIELDS = STUDENT_FIELDS.merge(componente_id: 'o componente curricular', nota: 'a nota').freeze
    LOG_LABELS = STUDENT_LOG_LABELS.merge(
      componente_id: 'componente',
      nota: 'nota',
      recuperacao: 'recuperação'
    ).freeze

    protected

    def payload_for(params)
      payload = {
        turma_id: integer_from(params, :turma_id, 'a turma'),
        aluno_id: integer_from(params, :aluno_id, 'o aluno'),
        componente_id: integer_from(params, :componente_id, 'o componente curricular'),
        etapa: step_from(params),
        nota: decimal_from(params, :nota, 'a nota')
      }

      payload[:recuperacao] = decimal_from(params, :recuperacao, 'a recuperação') if params[:recuperacao].present?

      payload
    end

    private

    def step_from(params)
      return FINAL_RECOVERY_STEP if params[:etapa].to_s == FINAL_RECOVERY_STEP

      integer_from(params, :etapa, 'a etapa')
    end

    # Float, e não BigDecimal: BigDecimal vira string no JSON, e o i-Educar valida número. `to_f`
    # devolveria 0 para lixo, e 0 é nota legítima.
    def decimal_from(params, key, description)
      Float(params[key].to_s)
    rescue ArgumentError, TypeError
      raise Base::ApiError, "O valor informado para #{description} não é um número"
    end
  end
end

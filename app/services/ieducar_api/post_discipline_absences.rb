module IeducarApi
  # Envia as faltas de um aluno em um componente curricular ao i-Educar
  # (POST /api/v2/falta-componente).
  #
  # Com `area_do_conhecimento_id`, o i-Educar grava as faltas no primeiro componente da área que
  # agrupa componentes na turma e zera os demais componentes do agrupamento.
  class PostDisciplineAbsences < V2Base
    POST_PATH = '/api/v2/falta-componente'.freeze
    LOG_PREFIX = '[falta-componente]'.freeze
    SUCCESS_MESSAGE = 'Faltas postadas com sucesso!'.freeze
    FIELDS = STUDENT_FIELDS.merge(faltas: 'as faltas', componente_id: 'o componente curricular').freeze
    LOG_LABELS = STUDENT_LOG_LABELS.merge(
      faltas: 'faltas',
      componente_id: 'componente',
      area_do_conhecimento_id: 'área do conhecimento'
    ).freeze

    protected

    def payload_for(params)
      payload = super

      if params[:area_do_conhecimento_id].present?
        payload[:area_do_conhecimento_id] = integer_from(
          params, :area_do_conhecimento_id, 'a área do conhecimento'
        )
      end

      payload
    end
  end
end

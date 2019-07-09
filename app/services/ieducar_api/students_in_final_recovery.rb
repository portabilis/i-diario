module IeducarApi
  class StudentsInFinalRecovery < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Turma',
        resource: 'alunos-exame-turma'
      )

      raise ApiError, 'É necessário informar a turma' if params[:classroom_api_code].blank?
      raise ApiError, 'É necessário informar a disciplina' if params[:discipline_api_code].blank?

      params['turma_id'] = params.delete(:classroom_api_code)
      params['disciplina_id'] = params.delete(:discipline_api_code)

      super
    end
  end
end

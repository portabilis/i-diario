module IeducarApi
  class StudentsInFinalRecovery < Base
    def fetch(params = {})
      raise ApiError.new('É necessário informar a turma: classroom_api_code') if params[:classroom_api_code].blank?
      raise ApiError.new('É necessário informar a disciplina: discipline_api_code') if params[:discipline_api_code].blank?

      params.reverse_merge!(path: 'module/Api/Turma', resource: 'alunos-exame-turma')

      params['turma_id'] = params.delete(:classroom_api_code)
      params['disciplina_id'] = params.delete(:discipline_api_code)

      super
    end
  end
end

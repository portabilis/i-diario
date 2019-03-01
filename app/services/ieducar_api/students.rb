module IeducarApi
  class Students < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Aluno',
        resource: 'todos-alunos'
      )

      super
    end

    def fetch_by_cpf(document, student_code)
      fetch(
        resource: 'alunos_by_guardian_cpf',
        cpf: document,
        aluno_id: student_code
      )
    end

    def fetch_registereds(params = {})
      params[:resource] = 'alunos-matriculados'

      raise ApiError, 'É necessário informar a escola: unity_code' if params[:unity_api_code].blank?
      raise ApiError, 'É necessário informar o ano: year' if params[:year].blank?
      raise ApiError, 'É necessário informar a data: date' if params[:date].blank?

      params['escola_id'] = params.delete(:unity_api_code)
      params['ano'] = params.delete(:year)
      params['data'] = params.delete(:date)
      params['curso_id'] = params.delete(:course_api_code)
      params['serie_id'] = params.delete(:grade_api_code)
      params['turma_id'] = params.delete(:classroom_api_code)
      params['turno_id'] = params.delete(:period)

      fetch(params)
    end
  end
end

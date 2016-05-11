# encoding: utf-8
module IeducarApi
  class Students < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Aluno", resource: "todos-alunos")

      super
    end

    def fetch_school_newsletter(params = {})
      params.merge!(path: "module/Api/Report", resource: "boletim")

      raise ApiError.new("É necessário informar a matricula: registration_id") if params[:registration_id].blank?
      raise ApiError.new("É necessário informar a escola: school_id") if params[:school_id].blank?

      params["matricula_id"] = params.delete(:registration_id)
      params["escola_id"] = params.delete(:school_id)

      fetch(params)
    end

    def fetch_by_cpf(document, student_code)
      fetch(
        resource: "alunos_by_guardian_cpf",
        cpf: document,
        aluno_id: student_code
      )
    end

    def fetch_registereds(params = {})
      params.merge!(resource: "alunos-matriculados")

      raise ApiError.new("É necessário informar a escola: unity_code") if params[:unity_api_code].blank?
      raise ApiError.new("É necessário informar o ano: year") if params[:year].blank?
      raise ApiError.new("É necessário informar a data: date") if params[:date].blank?

      params["escola_id"] = params.delete(:unity_api_code)
      params["ano"] = params.delete(:year)
      params["data"] = params.delete(:date)
      params["curso_id"] = params.delete(:course_api_code)
      params["serie_id"] = params.delete(:grade_api_code)
      params["turma_id"] = params.delete(:classroom_api_code)
      params["turno_id"] = params.delete(:period)

      fetch(params)
    end

    def fetch_for_daily(params = {})

      params.merge!(
        path: 'module/Api/Turma',
        resource: 'alunos-matriculados-turma'
      )

      raise ApiError.new('É necessário informar a turma: classroom_id!') if params[:classroom_api_code].blank?

      params['turma_id'] = params.delete(:classroom_api_code)
      params['disciplina_id'] = params.delete(:discipline_api_code)
      params['data_matricula'] = params.delete(:date)

      fetch(params)
    end
  end
end

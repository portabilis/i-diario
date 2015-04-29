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

    def fetch_for_daily(params = {})

      params.merge!(
        path: 'module/Api/Turma',
        resource: "alunos-matriculados-turma"
      )

      raise ApiError.new("É necessário informar a turma: classroom_id!") if params[:classroom_api_code].blank?

      params["turma_id"] = params.delete(:classroom_api_code)
      params["disciplina_id"] = params.delete(:discipline_api_code)

      fetch(params)
    end
  end
end

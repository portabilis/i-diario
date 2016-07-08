# encoding: utf-8
module IeducarApi
  class Teachers < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Servidor", resource: "servidores-disciplinas-turmas")

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end

    def fetch_teacher_report_card(params = {})
      params.merge!(path: "module/Api/Report", resource: "boletim-professor")

      raise ApiError.new("É necessário informar a escola: unity_id") if params[:unity_id].blank?
      raise ApiError.new("É necessário informar o curso: course_id") if params[:course_id].blank?
      raise ApiError.new("É necessário informar a série: grade_id") if params[:grade_id].blank?
      raise ApiError.new("É necessário informar a turma: classroom_id") if params[:classroom_id].blank?
      raise ApiError.new("É necessário informar a disciplina: discipline_id") if params[:discipline_id].blank?

      params["escola_id"] = params.delete(:unity_id)
      params["curso_id"] = params.delete(:course_id)
      params["serie_id"] = params.delete(:grade_id)
      params["turma_id"] = params.delete(:classroom_id)
      params["componente_curricular_id"] = params.delete(:discipline_id)

      fetch(params)
    end
  end
end

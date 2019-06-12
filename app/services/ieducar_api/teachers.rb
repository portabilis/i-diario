module IeducarApi
  class Teachers < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Servidor',
        resource: 'servidores'
      )

      super
    end

    def fetch_teacher_report_card(params = {})
      params[:path] = 'module/Api/Report'
      params[:resource] = 'boletim-professor'

      raise ApiError, 'É necessário informar a escola' if params[:unity_id].blank?
      raise ApiError, 'É necessário informar o curso' if params[:course_id].blank?
      raise ApiError, 'É necessário informar a série' if params[:grade_id].blank?
      raise ApiError, 'É necessário informar a turma' if params[:classroom_id].blank?
      raise ApiError, 'É necessário informar a disciplina' if params[:discipline_id].blank?

      params['escola_id'] = params.delete(:unity_id)
      params['curso_id'] = params.delete(:course_id)
      params['serie_id'] = params.delete(:grade_id)
      params['turma_id'] = params.delete(:classroom_id)
      params['componente_curricular_id'] = params.delete(:discipline_id)

      fetch(params)
    end
  end
end

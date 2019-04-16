module IeducarApi
  class TeacherDisciplineClassrooms < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Servidor',
        resource: 'servidores-disciplinas-turmas'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?

      super
    end
  end
end

module IeducarApi
  class StudentRegistrations < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Aluno',
        resource: 'matriculas',
        only_valid_boletim: true
      )

      raise ApiError, 'É necessário informar o código do aluno' if params[:aluno_id].blank?

      super
    end
  end
end

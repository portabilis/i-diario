module IeducarApi
  class PostExams < Base
    def send_post(params = {})
      params.reverse_merge!(path: 'module/Api/Diario', resource: 'notas')

      raise ApiError.new('É necessário informar as notas dos alunos') if params[:notas].blank?
      raise ApiError.new('É necessário informar a etapa') if params[:etapa].blank?
      raise ApiError.new('É necessário informar a turma') if params[:turma_id].blank?

      super
    end
  end
end

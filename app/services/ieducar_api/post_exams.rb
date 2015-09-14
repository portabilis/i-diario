module IeducarApi
  class PostExams < Base
    def send_post(params = {})
      params.reverse_merge!(path: 'module/Api/Diario', resource: 'notas')

      raise ApiError.new('É necessário informar as turmas') if params[:turmas].blank?
      raise ApiError.new('É necessário informar a etapa') if params[:etapa].blank?

      super
    end
  end
end

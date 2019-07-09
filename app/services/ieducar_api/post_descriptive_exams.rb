module IeducarApi
  class PostDescriptiveExams < Base
    def send_post(params = {})
      params.reverse_merge!(
        path: 'module/Api/Diario'
      )

      raise ApiError, 'É necessário informar os pareceres' if params[:pareceres].blank?
      raise ApiError, 'É necessário informar o recurso' if params[:resource].blank?

      super
    end
  end
end

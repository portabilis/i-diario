module IeducarApi
  class PostAbsences < Base
    def send_post(params = {})
      params.reverse_merge!(
        path: 'module/Api/Diario'
      )

      raise ApiError, 'É necessário informar o recurso' if params[:resource].blank?
      raise ApiError, 'É necessário informar a etapa' if params[:etapa].blank?
      raise ApiError, 'É necessário informar as faltas' if params[:faltas].blank?

      super
    end
  end
end

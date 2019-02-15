module IeducarApi
  class PostRecoveries < Base
    def send_post(params = {})
      params.reverse_merge!(
        path: 'module/Api/Diario'
      )

      raise ApiError, 'É necessário informar as notas' if params[:notas].blank?
      raise ApiError, 'É necessário informar a etapa' if params[:etapa].blank?
      raise ApiError, 'É necessário informar o recurso' if params[:resource].blank?

      super
    end
  end
end

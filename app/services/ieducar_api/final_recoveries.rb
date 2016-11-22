module IeducarApi
  class FinalRecoveries < Base
    def send_post(params = {})
      raise ApiError.new('É necessário informar as turmas') if params[:notas].blank?

      params.reverse_merge!(path: 'module/Api/Diario', resource: 'notas', etapa: 'Rc')

      super
    end
  end
end

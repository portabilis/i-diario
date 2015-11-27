module IeducarApi
  class FinalRecoveries < Base
    def post(params = {})
      raise ApiError.new('É necessário informar as turmas') if params[:turmas].blank?

      params.reverse_merge!(path: 'module/Api/Diario', resource: 'notas', etapa: 'Rc')

      super
    end
  end
end

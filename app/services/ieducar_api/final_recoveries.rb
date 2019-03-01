module IeducarApi
  class FinalRecoveries < Base
    def send_post(params = {})
      params.reverse_merge!(
        path: 'module/Api/Diario',
        resource: 'notas',
        etapa: 'Rc'
      )

      raise ApiError, 'É necessário informar as turmas' if params[:notas].blank?

      super
    end
  end
end

module IeducarApi
  class Deficiencies < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Deficiencia',
        resource: 'deficiencias'
      )

      raise ApiError, 'É necessário informar pelo menos uma escola' if params[:escola].blank?

      super
    end
  end
end

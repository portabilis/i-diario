module IeducarApi
  class UnityParams < Base
    def fetch(params = {})
      params[:path] = 'module/Api/Escola'
      params[:resource] = 'parametros-escolas'

      super
    end
  end
end

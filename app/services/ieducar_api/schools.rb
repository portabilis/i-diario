module IeducarApi
  class Schools < Base
    def fetch_all(params = {})
      params[:path] = 'module/Api/Escola'
      params[:resource] = 'info-escolas'

      fetch(params)
    end
  end
end

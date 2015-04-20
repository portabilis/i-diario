# encoding: utf-8
module IeducarApi
  class Teachers < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Servidor", resource: "servidores-disciplinas-turmas")

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end
  end
end

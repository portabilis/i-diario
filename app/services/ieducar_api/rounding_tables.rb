# encoding: utf-8
module IeducarApi
  class RoundingTables < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Regra", resource: "tabelas-de-arredondamento")
      super
    end
  end
end

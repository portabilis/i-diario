# encoding: utf-8
module IeducarApi
  class Deficiencies < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Deficiencia", resource: "deficiencias")

      super
    end
  end
end

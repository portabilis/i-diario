module IeducarApi
  class Grades < Base
    def fetch(params = {})
      params[:path] = 'module/Api/Serie'
      params[:resource] = 'series'

      super
    end
  end
end

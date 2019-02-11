module IeducarApi
  class Disciplines < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/ComponenteCurricular',
        resource: 'componentes-curriculares'
      )

      super
    end
  end
end

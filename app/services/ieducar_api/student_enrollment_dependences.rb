module IeducarApi
  class StudentEnrollmentDependences < Base
    def fetch(params = {})
      params.reverse_merge!(
        path: 'module/Api/Matricula',
        resource: 'matriculas-dependencia'
      )

      raise ApiError, 'É necessário informar o ano' if params[:ano].blank?

      super
    end
  end
end

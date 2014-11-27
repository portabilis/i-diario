class StudentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:search_api]

  def index
    @students = apply_scopes(Student)

    respond_with @students
  end

  def search_api
    begin
      api = IeducarApi::Students.new(configuration.to_api)
      result = api.fetch_by_cpf(params[:document], params[:student_code])

      render json: result["alunos"].to_json
    rescue IeducarApi::Base::ApiError => e
      render json: e.message, status: "404"
    end
  end

  protected

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end
end

# encoding: utf-8
class DisciplinaryIncidentsController < ApplicationController
  def index
    begin
      result = api.fetch(aluno_id: students_code)

      @disciplinary_incidents = DisciplinaryIncident.all(result["ocorrencias_disciplinares"])

      authorize DisciplinaryIncident, :index?
    rescue IeducarApi::Base::ApiError => e
      redirect_to root_path, alert: e.message
    end
  end

  protected

  def api
    @api ||= IeducarApi::DisciplinaryIncidents.new(current_configuration.to_api)
  end

  def students_code
    current_user.student_api_codes
  end
end

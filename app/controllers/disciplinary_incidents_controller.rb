# encoding: utf-8
class DisciplinaryIncidentsController < ApplicationController
  def index
    result = api.fetch(aluno_id: students_code)

    @disciplinary_incidents = DisciplinaryIncident.all(result["ocorrencias_disciplinares"])
  end

  protected

  def api
    @api ||= IeducarApi::DisciplinaryIncidents.new(current_configuration.to_api)
  end

  # TODO: por enquanto está retornando os 20 primeiros alunos sincronizados
  # Quando for feito o vínculo do pai com os alunos este método deverá retornar
  # somente os alunos vinculados
  def students_code
    Student.limit(20).pluck(:api_code)
  end
end

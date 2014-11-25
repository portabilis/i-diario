# encoding: utf-8
module IeducarApi
  class StudentRegistrations < Base
    def fetch(params = {})
      params.reverse_merge!(path: "module/Api/Aluno", resource: "matriculas", only_valid_boletim: true)

      raise ApiError.new("É necessário informar os códigos dos alunos: aluno_id") if params[:aluno_id].blank?

      super
    end
  end
end

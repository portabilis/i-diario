# encoding: utf-8
module IeducarApi
  class Classrooms < Base
    def fetch(params = {})
      Rails.logger.debug params.inspect
      params.reverse_merge!(path: "module/Api/Turma", resource: "turmas-por-escola")
      Rails.logger.debug "@@@@@@@@@@@@@@@@@"
      Rails.logger.debug params.inspect
      Rails.logger.debug "@@@@@@@@@@@@@@@@@"

      raise ApiError.new("É necessário informar o ano") if params[:ano].blank?
      super
    end
  end
end

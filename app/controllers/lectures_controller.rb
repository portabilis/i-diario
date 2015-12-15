class LecturesController < ApplicationController
  respond_to :json

  def index
    api_codes = Unity.where(id: params[:unity_ids].split(',')).pluck(:api_code).uniq

    result = api.fetch escola_id: api_codes
    @lectures = Lecture.all(result["cursos"])
  end

  protected

  def api
    @api ||= IeducarApi::Lectures.new current_configuration.to_api
  end
end

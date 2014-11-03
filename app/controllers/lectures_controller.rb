class LecturesController < ApplicationController
  respond_to :json

  def index
    @lectures = Lecture.all(result["cursos"])
  end

  protected

  def result
    api.fetch escola_id: params[:escola_id]
  end

  def api
    @api ||= IeducarApi::Lectures.new current_configuration.to_api
  end
end

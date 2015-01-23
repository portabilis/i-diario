class SchoolsController < ApplicationController
  respond_to :json

  def index
    begin
      codes = result["escolas"].map { |r| r["cod_escola"] }

      @unities = Unity.where(api_code: codes)
    rescue Exception => e
      render json: { error: e.message }, status: :not_found
    end
  end

  protected

  def result
    api.fetch_with_vacancy(
      ano: params[:year],
      curso_id: params[:lecture_id],
      serie_id: params[:grade_id],
      turma_turno_id: params[:period]
    )
  end

  def api
    @api ||= IeducarApi::Schools.new current_configuration.to_api
  end
end

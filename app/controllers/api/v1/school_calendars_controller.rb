class Api::V1::SchoolCalendarsController < Api::V1::BaseController
  respond_to :json

  def index
    unity_id = params[:unity_id]
    return unless unity_id

    render json: SchoolCalendar.find_by(year: Date.today.year, unity_id: unity_id)
  end
end

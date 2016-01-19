class Api::V1::SchoolCalendarsController < Api::V1::BaseController
  respond_to :json

  def index
    unity_id = params[:unity_id]
    return unless unity_id

    render json: CurrentSchoolCalendarFetcher.new(unity_id).fetch
  end
end

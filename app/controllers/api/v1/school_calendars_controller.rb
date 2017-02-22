class Api::V1::SchoolCalendarsController < Api::V1::BaseController
  respond_to :json

  def index
    unity = Unity.find_by_id(params[:unity_id])
    return unless unity

    render json: CurrentSchoolCalendarFetcher.new(unity, nil).fetch
  end
end

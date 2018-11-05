class Api::V2::TeacherUnitiesController < Api::V2::BaseController
  respond_to :json

  def index
    return unless params[:teacher_id]
    @unities = Unity.by_teacher(params[:teacher_id]).
                     by_year(Date.current.year).
                     ordered.
                     uniq
  end
end

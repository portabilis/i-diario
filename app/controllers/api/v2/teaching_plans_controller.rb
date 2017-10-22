class Api::V2::TeachingPlansController < Api::V2::BaseController
  respond_to :json

  def index
    return unless params[:teacher_id]
    @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
    @teacher_id = params[:teacher_id]
  end
end

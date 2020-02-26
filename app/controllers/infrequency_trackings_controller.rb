class InfrequencyTrackingsController < ApplicationController
  has_scope :page, default: 1, only: :index
  has_scope :per, default: 10, only: :index

  def index
    @infrequency_trackings = apply_scopes(
      InfrequencyTracking.includes(:student, classroom: [:unity, :grade])
                         .joins(:classroom)
                         .merge(classrooms)
                         .ordered
    )

    authorize @infrequency_trackings
  end

  private

  def unities
    @unities ||= current_unities.by_year(current_user_school_year).reorder('')
  end
  helper_method :unities

  def classrooms
    @classrooms ||= Classroom.by_unity(unities.pluck(:id))
                             .by_year(current_user_school_year)
  end
  helper_method :classrooms

  def grades
    @grades ||= Grade.joins(:classrooms).merge(classrooms).uniq
  end
  helper_method :grades
end

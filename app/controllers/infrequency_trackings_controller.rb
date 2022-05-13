class InfrequencyTrackingsController < ApplicationController
  has_scope :page, default: 1, only: :index
  has_scope :per, default: 10, only: :index

  def index
    @infrequency_trackings = apply_scopes(
      InfrequencyTracking.includes(
        :mvw_infrequency_tracking_classroom,
        :student,
        classroom: [:unity, classrooms_grades: :grade]
      ).joins(
        :mvw_infrequency_tracking_classroom,
        :student,
        classroom: [:unity, classrooms_grades: :grade]
      ).merge(classrooms).ordered
    )

    authorize @infrequency_trackings
  end

  private

  def unities
    @unities ||= begin
      unities = Unity.all if current_user.has_administrator_access_level?
      unities ||= Unity.by_user_id(current_user.id).by_infrequency_tracking_permission
      unities.by_year(current_school_year)
    end
  end
  helper_method :unities

  def classrooms
    @classrooms ||= MvwInfrequencyTrackingClassroom.by_year(current_school_year)
                                                   .by_unity_id(unities.pluck(:id))
  end
  helper_method :classrooms

  def grades
    @grades ||= Grade.joins(:mvw_infrequency_tracking_classrooms).merge(classrooms).uniq
  end
  helper_method :grades

  def students
    @students ||= MvwInfrequencyTrackingStudent.by_year(current_school_year)
  end
  helper_method :students
end

class ActiveSearch < ActiveRecord::Base
  belongs_to :student_enrollment

  has_enumeration_for :status, with: ActiveSearchStatus, create_helpers: true

  def in_active_search?(student_enrollment_id, date)
    student_active_search = ActiveSearch.where(student_enrollment_id: student_enrollment_id)
    not_in_progress = student_active_search.where.not(status: ActiveSearchStatus::IN_PROGRESS)
                                           .where('? between start_date and end_date', date)
                                           .exists?
    return not_in_progress if not_in_progress

    student_active_search.where(status: ActiveSearchStatus::IN_PROGRESS)
                         .where('start_date <= ?', date)
                         .exists?
  end
end

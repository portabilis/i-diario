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

  def in_active_search_in_range(student_enrollments_ids, dates)
    in_active_searchs = []
    dates.each do |date|
      students_active_searchs = ActiveSearch.where(student_enrollment_id: student_enrollments_ids)

      active_search_students_ids = []

      active_search_students_ids = students_active_searchs.where(status: ActiveSearchStatus::IN_PROGRESS)
                                                                     .where('start_date <= ?', date)
                                                                     .includes(student_enrollment: [:student])
                                                                     .pluck('students.id')
      active_search_students_ids = nil if active_search_students_ids.empty?

      in_active_searchs << build_hash(date, active_search_students_ids)
    end
    in_active_searchs.compact
  end

  def build_hash(date, student_ids)
    return if student_ids.nil?

    {
      date: date,
      student_ids: student_ids
    }
  end
end

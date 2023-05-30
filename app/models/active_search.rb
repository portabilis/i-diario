class ActiveSearch < ApplicationRecord
  include Audit
  include Discardable

  belongs_to :student_enrollment

  audited
  has_associated_audits

  has_enumeration_for :status, with: ActiveSearchStatus, create_helpers: true

  default_scope -> { kept }

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
    students_active_searchs = ActiveSearch.where(student_enrollment_id: student_enrollments_ids)
                                          .includes(student_enrollment: [:student])
    in_active_searchs = []

    dates.each do |date|
      active_search_students_ids = []
      students_active_searchs.each do |students_active_search|
        next if date < students_active_search.start_date

        if students_active_search.end_date.nil? || date <= students_active_search.end_date
          active_search_students_ids << students_active_search.student_enrollment.student.id
        end
      end
      in_active_searchs << build_hash(date, active_search_students_ids)
    end
    in_active_searchs
  end

  def enrollments_in_active_search?(student_enrollments_ids, date)
    students_active_searches = ActiveSearch.where(student_enrollment_id: student_enrollments_ids)
                                           .includes(student_enrollment: [:student])
    in_active_searches = {}

    students_active_searches.each do |students_active_search|
      next if date < students_active_search.start_date

      if students_active_search.end_date.nil? || date <= students_active_search.end_date
        in_active_searches[date] ||= []
        in_active_searches[date] << students_active_search.student_enrollment_id
      end
    end

    in_active_searches
  end

  def build_hash(date, student_ids)
    return if student_ids.nil?

    {
      date: date,
      student_ids: student_ids
    }
  end
end

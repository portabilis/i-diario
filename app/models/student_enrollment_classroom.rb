class StudentEnrollmentClassroom < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :student_enrollment

  scope :by_classroom, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_date, lambda { |date| where("(? >= joined_at AND ? < left_at) OR (? >= joined_at AND coalesce(left_at) = '')", date.to_date, date.to_date, date.to_date) }
  scope :by_date_range, lambda { |start_at, end_at| self.by_date_range_query(start_at, end_at)}
  scope :by_date_not_before, lambda { |date| where.not('joined_at < ?', date) }
  scope :show_as_inactive, lambda { where(show_as_inactive_when_not_in_date: 't') }
  scope :by_grade, lambda { |grade_id| joins(:classroom).where(classrooms: { grade_id: grade_id })   }
  scope :by_student, lambda { |student_id| joins(student_enrollment: :student).where(students: { id: student_id })   }

  def delete_invalid_presence_record
    if left_classroom?
      DailyFrequency.by_unity_classroom_and_frequency_date_between(classroom.unity_id, classroom_id,
                                                                                       left_at,
                                                                                       Time.zone.now).has_frequency_for_student(student_enrollment.student_id)
                                                                                                     .each do |daily_frequency|
        daily_frequency.find_by_student(student_enrollment.student.id).destroy
      end
    end
  end

  private

  def self.by_date_range_query(start_at, end_at)
    where("(CASE WHEN COALESCE(student_enrollment_classrooms.left_at) = ''
            THEN
              student_enrollment_classrooms.joined_at <= ?
            ELSE
              student_enrollment_classrooms.joined_at <= ? AND student_enrollment_classrooms.left_at >= ?
            END)", end_at.to_date, end_at.to_date, start_at.to_date)
  end

  def left_classroom?
    !left_at.blank?
  end
end

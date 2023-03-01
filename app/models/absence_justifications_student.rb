class AbsenceJustificationsStudent < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :student
  belongs_to :absence_justification

  before_destroy :remove_justification_from_frequencies
  after_save :justify_old_absences

  default_scope -> { kept }

  private

  def remove_justification_from_frequencies
    daily_frequency_students = DailyFrequencyStudent.by_absence_justification_student_id(id)

    daily_frequency_students.each do |daily_frequency_student|
      daily_frequency_student.absence_justification_student_id = nil
      daily_frequency_student.save
    end
  end

  def justify_old_absences
    absence_date = absence_justification.absence_date
    absence_date_end = absence_justification.absence_date_end
    classroom_id = absence_justification.classroom_id

    daily_frequency_students = DailyFrequencyStudent.by_classroom_id(classroom_id)
                                                    .by_frequency_date_between(absence_date, absence_date_end)
                                                    .by_student_id(student_id)

    daily_frequency_students.each do |daily_frequency_student|
      daily_frequency_student.present = false
      daily_frequency_student.absence_justification_student_id = id
      daily_frequency_student.save
    end
  end
end

class AbsenceJustificationsStudent < ApplicationRecord
  include Discardable

  audited

  belongs_to :student
  belongs_to :absence_justification
  has_many :daily_frequency_students, dependent: :nullify, foreign_key: :absence_justification_student_id

  after_save :justify_old_absences

  default_scope -> { kept }

  private

  def justify_old_absences
    absence_date = absence_justification.absence_date
    absence_date_end = absence_justification.absence_date_end
    classroom_id = absence_justification.classroom_id

    daily_frequency_students = DailyFrequencyStudent.by_classroom_id(classroom_id)
                                                    .by_frequency_date_between(absence_date, absence_date_end)
                                                    .by_student_id(student_id)

    daily_frequency_students = daily_frequency_students.by_class_number(absence_justification.class_number) if absence_justification.class_number.present?

    if absence_justification.period.present?
      periods = if absence_justification.period == Periods::FULL
                  [Periods::MATUTINAL, Periods::VESPERTINE, Periods::NIGHTLY, Periods::FULL]
                else
                  absence_justification.period
                end

      daily_frequency_students.by_period(periods)
    end

    daily_frequency_students.each do |daily_frequency_student|
      daily_frequency_student.present = false
      daily_frequency_student.absence_justification_student_id = id
      daily_frequency_student.save
    end
  end
end

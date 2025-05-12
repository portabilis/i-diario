# frozen_string_literal: true

class AbsenceJustifiedOnDate
  attr_reader :date, :end_date, :classroom, :students, :period

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @students = params.fetch(:students)
    @date = params.fetch(:date)
    @end_date = params.fetch(:end_date)
    @classroom = params.fetch(:classroom)
    @period = params.fetch(:period)
  end

  def call
    periods = period.nil? ? Periods.to_hash.except("Intermediário").values.push(nil) : period

    absence_justified_on_date(periods)
  end

  def absence_justified_on_date(periods)
    absence_justifications = AbsenceJustification.includes(:absence_justifications_students)
                                                 .by_date_range(date, end_date)
                                                 .by_student_id(students)
                                                 .by_classroom(classroom)
                                                 .by_period(periods)

    absence_justified = {}

    absence_justifications.each do |absence_justification|
      class_number = absence_justification.class_number || 0
      dates = absence_justification.absence_date..absence_justification.absence_date_end

      dates.each do |date|
        absence_justification.absence_justifications_students.each do |absence_justifications_student|
          absence_justified[absence_justifications_student.student_id] ||= {}
          absence_justified[absence_justifications_student.student_id][date] ||= {}
          absence_justified[absence_justifications_student.student_id][date][class_number] = absence_justifications_student.id
        end
      end
    end

    absence_justified
  end
end

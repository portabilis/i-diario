# frozen_string_literal: true

class AbsenceJustifiedOnDate
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @students = params.fetch(:students)
    @date = params.fetch(:date)
    @end_date = params.fetch(:end_date)
    @classroom = params.fetch(:classroom)
  end

  def call
    absence_justifications = AbsenceJustification.includes(:absence_justifications_students)
                                                 .by_date_range(@date, @end_date)
                                                 .by_student_id(@students)
                                                 .by_classroom(@classroom)

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

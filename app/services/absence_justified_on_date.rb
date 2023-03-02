# frozen_string_literal: true

class AbsenceJustifiedOnDate
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @students = params.fetch(:students)
    @date = params.fetch(:date)
  end

  def call
    absence_justifications = AbsenceJustification.includes(:absence_justifications_students)
                                                 .by_date(@date)
                                                 .by_student_id(@students)

    absence_justified = {}

    absence_justifications.each do |absence_justification|
      class_number = absence_justification.class_number || 0

      absence_justification.absence_justifications_students.each do |absence_justifications_student|
        absence_justified[absence_justifications_student.student_id] ||= {}
        absence_justified[absence_justifications_student.student_id][@date] ||= {}
        absence_justified[absence_justifications_student.student_id][@date][class_number] = absence_justifications_student.id
      end
    end

    absence_justified
  end
end

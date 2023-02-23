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
    absence_justifications = AbsenceJustification.by_date(@date).by_student_id(@students)

    absence_justified = {}

    absence_justifications.each do |absence_justification|
      absence_justification.students.each do |student|
        absence_justified[student.id] ||= {}
        absence_justified[student.id][@date] = absence_justification.id
      end
    end

    absence_justified
  end
end

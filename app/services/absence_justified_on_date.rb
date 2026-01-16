# frozen_string_literal: true

class AbsenceJustifiedOnDate
  attr_reader :date, :end_date, :classroom_id, :students, :period

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @students = params.fetch(:students)
    @date = params.fetch(:date)
    @end_date = params.fetch(:end_date)
    @classroom_id = params.fetch(:classroom)
    @period = params.fetch(:period)
  end

  def call
    periods = normalize_periods

    absence_justified_on_date(periods)
  end

  def absence_justified_on_date(periods)
    absence_justifications = AbsenceJustification.includes(:absence_justifications_students)
                                                 .by_date_range(date, end_date)
                                                 .by_student_id(students)
                                                 .by_classroom(classroom_id)
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

  private

  def normalize_periods
    classroom_period = classroom.period

    if period.nil? || period.to_s == Periods::FULL
      Periods.for_full.push(nil)
    elsif classroom_period == Periods::FULL
      # Period é do professor, porem se a turma for integral(FULL), é necessário filtrar o turno do professor + turno FULL e nil para listar as justificativas.
      [period.to_s, Periods::FULL, nil]
    else
      period
    end
  end

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
  end
end

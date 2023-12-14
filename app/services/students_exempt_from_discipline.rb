# frozen_string_literal: true

class StudentsExemptFromDiscipline
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollments = params.fetch(:student_enrollments)
    @discipline = params.fetch(:discipline)
    @step = params.fetch(:step)
  end

  def call
    return {} if @discipline.blank? || @student_enrollments.blank?

    student_enrollments_exempt = StudentEnrollmentExemptedDiscipline.by_discipline(@discipline.id)
                                                                    .by_step_number(@step)
                                                                    .by_student_enrollment(@student_enrollments)
                                                                    .includes(student_enrollment: [:student])

    student_has_exempt_for_step(student_enrollments_exempt)
  rescue NoMethodError => errors
    raise errors
  end

  private

  def student_has_exempt_for_step(student_enrollments_exempt)
    exempts_from_discipline = {}

    student_enrollments_exempt.each do |student_exempted|
      exempts_from_discipline[student_exempted.student_enrollment_id] ||= @step
    end

    exempts_from_discipline
  end
end

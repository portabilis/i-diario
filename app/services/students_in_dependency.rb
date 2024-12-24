# frozen_string_literal: true

class StudentsInDependency
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollments = params.fetch(:student_enrollments)
    @disciplines = params.fetch(:disciplines)
  end

  def call
    return {} unless @disciplines || @student_enrollments

    student_enrollment_dependencies = StudentEnrollmentDependence.where(
      student_enrollment_id: @student_enrollments,
      discipline_id: @disciplines
    )

    student_has_dependency_for_discipline(student_enrollment_dependencies)
  rescue NoMethodError => errors
    raise errors
  end

  private

  def student_has_dependency_for_discipline(student_enrollment_dependencies)
    dependencies = {}

    student_enrollment_dependencies.each do |student_enrollment_dependence|
      student_enrollment_id = student_enrollment_dependence.student_enrollment_id
      discipline_id = student_enrollment_dependence.discipline_id

      dependencies[student_enrollment_id] ||= []
      dependencies[student_enrollment_id] << discipline_id
    end

    dependencies
  end
end

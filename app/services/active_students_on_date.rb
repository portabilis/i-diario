# frozen_string_literal: true

class ActiveStudentsOnDate
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @student_enrollments = params.fetch(:student_enrollments)
    @date = params.fetch(:date)
  end

  def call
    enrollment_classrooms = StudentEnrollmentClassroom.by_student_enrollment(@student_enrollments)
                                                      .by_date(@date)

    student_active_on_date(enrollment_classrooms)
  end

  private

  def student_active_on_date(enrollment_classrooms)
    active_on_date = {}

    enrollment_classrooms.each do |enrollment_classroom|
      active_on_date[enrollment_classroom.id] ||= []
      active_on_date[enrollment_classroom.id] << @date
    end

    active_on_date
  end
end

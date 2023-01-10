# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentsInDependency, type: :service do
  context '#call' do
    let(:student_enrollments) { create_list(:student_enrollment, 2) }
    let(:disciplines) { create_list(:discipline, 2) }

    it 'should returns student_enrollments with student in dependency' do
      create_dependencies_for_disciplines(student_enrollments, disciplines)

      subject = StudentsInDependency.call(
        student_enrollments: student_enrollments,
        disciplines: disciplines
      )

      expect(subject).to include(
        { student_enrollments.first.id => [disciplines.first.id] },
        { student_enrollments.last.id => [disciplines.last.id] }
      )
      expect(subject.size).to eql(2)
    end

    it 'should not returns student_enrollments with student without dependency' do
      subject = StudentsInDependency.call(
        student_enrollments: student_enrollments,
        disciplines: disciplines
      )

      expect(subject).to be_empty
    end
  end
end

def create_dependencies_for_disciplines(student_enrollments, disciplines)
  create(
    :student_enrollment_dependence,
    student_enrollment: student_enrollments.first,
    discipline: disciplines.first
  )
  create(
    :student_enrollment_dependence,
    student_enrollment: student_enrollments.last,
    discipline: disciplines.last
  )
end

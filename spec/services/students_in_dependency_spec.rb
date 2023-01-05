# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentsInDependency, type: :service do
  context '#call' do
    let(:student_enrollments) { create_list(:student_enrollment, 2) }
    let(:disciplines) { create_list(:discipline, 2) }

    before do
      disciplines
      student_enrollments
    end

    it 'should returns student_enrollments with student with dependency' do
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

      subject = StudentsInDependency.call(
        student_enrollments: student_enrollments,
        discipline: disciplines
      )

      expect(subject).to include(
        { student_enrollments.first.id => [disciplines.first.id] },
        { student_enrollments.last.id => [disciplines.last.id] }
      )
    end

    it 'should not returns student_enrollments with student without dependency' do
      subject = StudentsInDependency.call(
        student_enrollments: student_enrollments,
        discipline: disciplines
      )

      expect(subject).to be_empty
    end
  end
end

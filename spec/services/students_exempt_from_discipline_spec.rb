# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentsExemptFromDiscipline, type: :service do
  context '#call' do
    let(:discipline) { create(:discipline) }
    let(:student_enrollments) { create_list(:student_enrollment, 3) }
    before do
      discipline
      student_enrollments
    end

    it 'should returns student_enrollments with students exempt from discipline' do
      create_enrollments_exempted(student_enrollments, discipline)
      student_enrollment_ids = student_enrollments.map(&:id)

      subject = StudentsExemptFromDiscipline.call(
        student_enrollments: student_enrollments,
        discipline: discipline,
        step: 1
      )

      expect(subject).to include(
        { student_enrollment_ids.first => 1 },
        { student_enrollment_ids.second => 1 },
        { student_enrollment_ids.last => 1 }
      )
      expect(subject.size).to be(3)
    end

    it 'should not returns student_enrollments without exempt from discipline' do
      student_enrollment_ids = student_enrollments.map(&:id)

      subject = StudentsExemptFromDiscipline.call(
        student_enrollments: student_enrollments,
        discipline: discipline,
        step: 1
      )

      expect(subject).not_to include(
        { student_enrollment_ids.first => 1 },
        { student_enrollment_ids.second => 1 },
        { student_enrollment_ids.last => 1 }
      )
    end

    it 'error' do
      subject = StudentsExemptFromDiscipline.call(
        student_enrollments: student_enrollments,
        discipline: discipline,
        step: '2022-02-02'
      )

      expect(subject).should_not be_valid
    end
  end
end

def create_enrollments_exempted(student_enrollments, discipline)
  student_enrollment_exempted_disciplines = []

  student_enrollments.each do |student_enrollment|
    enrollment_exempted = create(
      :student_enrollment_exempted_discipline,
      student_enrollment: student_enrollment,
      discipline: discipline
    )

    student_enrollment_exempted_disciplines << enrollment_exempted
  end

  student_enrollment_exempted_disciplines
end

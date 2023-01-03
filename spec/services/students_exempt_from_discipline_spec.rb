# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentsExemptFromDiscipline, type: :service do
  let!(:student_enrollment_classroom_2) { create(:student_enrollment_classroom) }
  let!(:student_enrollment_classroom) { create(:student_enrollment_classroom) }
  let!(:discipline) { create(:discipline) }
  let!(:student_enrollment_exempted_discipline) {
    create(
      :student_enrollment_exempted_discipline,
      student_enrollment_id: student_enrollment_classroom.student_enrollment_id,
      discipline_id: discipline.id
    )
  }


  context '#call' do
    it 'should returns student_enrollment with student exempt from discipline' do
      subject = described_class.call(
        student_enrollments: student_enrollment_classroom.student_enrollment_id,
        discipline: discipline,
        steps: 1
      )

      expect(subject).to include(student_enrollment_classroom.student_enrollment_id)
    end

    it 'should returns hash empty for student without exempt' do
      subject = described_class.call(
        student_enrollments: student_enrollment_classroom_2.student_enrollment_id,
        discipline: discipline,
        steps: 1
      )

      expect(subject).to be_empty
    end
  end
end

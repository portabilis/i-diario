# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentsInDependency, type: :service do
  let!(:student_enrollment_classroom) { create(:student_enrollment_classroom) }
  let!(:student_enrollment_classroom_2) { create(:student_enrollment_classroom) }
  let!(:discipline) { create(:discipline) }
  let!(:student_enrollment_dependence) {
    create(
      :student_enrollment_dependence,
      student_enrollment_id: student_enrollment_classroom.student_enrollment_id,
      discipline_id: discipline.id
    )
  }

  context '#call' do
    it 'should returns student_enrollment with student in dependency' do
      subject = described_class.call(
        student_enrollments: student_enrollment_classroom.student_enrollment_id,
        discipline: discipline
      )

      expect(subject).to include(student_enrollment_classroom.student_enrollment_id)
    end

    let!(:student_enrollment_classroom_3) { create(:student_enrollment_classroom) }
    let!(:discipline_3) { create(:discipline) }
    let!(:student_enrollment_dependence_3) {
      create(
        :student_enrollment_dependence,
        student_enrollment_id: student_enrollment_classroom_3.student_enrollment_id,
        discipline_id: discipline_3.id
      )
    }

    it 'should returns student_enrollments with students in dependency in two disciplines' do
      subject = described_class.call(
        student_enrollments: [student_enrollment_classroom.student_enrollment, student_enrollment_classroom_3.student_enrollment],
        discipline: [discipline, discipline_3]
      )

      expect(subject).to include(student_enrollment_classroom.student_enrollment_id, student_enrollment_classroom_3.student_enrollment_id)
    end

    it 'should returns hash empty for student without dependency' do
      subject = described_class.call(
        student_enrollments: student_enrollment_classroom_2.student_enrollment_id,
        discipline: discipline
      )

      expect(subject).to be_empty
    end
  end
end

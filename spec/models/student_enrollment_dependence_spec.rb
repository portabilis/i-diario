# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentEnrollmentDependence, type: :model do
  describe '.discipline_ids_for' do
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
    let(:student) { create(:student) }
    let(:discipline) { create(:discipline) }
    let(:enrollment) { create(:student_enrollment, student: student) }

    before do
      create(
        :student_enrollment_classroom,
        classrooms_grade: classrooms_grade,
        student_enrollment: enrollment,
        joined_at: '2017-01-01'
      )
    end

    it 'returns the discipline ids the student has in dependence in the classroom' do
      create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline)

      result = described_class.discipline_ids_for(student.id, classroom.id)

      expect(result).to contain_exactly(discipline.id)
    end

    it 'returns an empty array when the student has no dependence in the classroom' do
      result = described_class.discipline_ids_for(student.id, classroom.id)

      expect(result).to eq([])
    end

    it 'returns an empty array when the student has no enrollment in the classroom' do
      other_student = create(:student)

      result = described_class.discipline_ids_for(other_student.id, classroom.id)

      expect(result).to eq([])
    end
  end
end

require 'rails_helper'

RSpec.describe ConceptualExamValue, type: :model do
  describe 'associations' do
    it { expect(subject).to belong_to(:conceptual_exam) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:conceptual_exam) }
    it { expect(subject).to validate_presence_of(:discipline_id) }
  end

  describe '.active' do
    let(:classroom) { create(:classroom, :score_type_concept_create_rule, :with_classroom_semester_steps) }
    let(:discipline) { create(:discipline) }
    let(:teacher) { create(:teacher) }
    let(:student) { create(:student) }

    let!(:teacher_discipline_classroom) do
      create(
        :teacher_discipline_classroom,
        teacher: teacher,
        classroom: classroom,
        discipline: discipline,
        score_type: ScoreTypes::CONCEPT
      )
    end

    let!(:conceptual_exam) do
      create(
        :conceptual_exam,
        :with_student_enrollment_classroom,
        :with_one_value,
        classroom: classroom,
        teacher_id: teacher.id,
        student: student,
        discipline: discipline
      )
    end

    let(:conceptual_exam_value) { conceptual_exam.conceptual_exam_values.first }

    it 'includes values whose teacher discipline classroom is active' do
      expect(described_class.active).to include(conceptual_exam_value)
    end

    it 'excludes values whose teacher discipline classroom is discarded' do
      expect(described_class.active).to include(conceptual_exam_value)

      teacher_discipline_classroom.discard

      expect(described_class.active).not_to include(conceptual_exam_value)
    end

    it 'excludes values whose teacher discipline classroom is inactive' do
      expect(described_class.active).to include(conceptual_exam_value)

      teacher_discipline_classroom.update_column(:active, false)

      expect(described_class.active).not_to include(conceptual_exam_value)
    end
  end
end

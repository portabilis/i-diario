require 'rails_helper'

RSpec.describe ClassroomsGrade, type: :model do
  describe 'attributes' do
    it { expect(subject).to respond_to(:classroom_id) }
    it { expect(subject).to respond_to(:grade_id) }
    it { expect(subject).to respond_to(:exam_rule_id) }
  end

  describe '.by_score_type' do
    # Regra regular numerica cuja regra DIFERENCIADA e conceitual: e o arranjo que
    # o i-Educar sincroniza quando a escola nao marca "utiliza regra diferenciada".
    let(:concept_exam_rule) { create(:exam_rule, :score_type_concept) }
    let(:numeric_exam_rule_with_differentiated) do
      create(:exam_rule, differentiated_exam_rule: concept_exam_rule)
    end

    def enroll_student(classrooms_grade, uses_differentiated_exam_rule:)
      student = create(:student, uses_differentiated_exam_rule: uses_differentiated_exam_rule)

      create(
        :student_enrollment_classroom,
        classrooms_grade: classrooms_grade,
        student_enrollment: create(:student_enrollment, student: student)
      )
    end

    it 'includes the grade when the differentiated exam rule matches and an enrolled student uses it' do
      classrooms_grade = create(:classrooms_grade, exam_rule: numeric_exam_rule_with_differentiated)
      enroll_student(classrooms_grade, uses_differentiated_exam_rule: true)

      result = described_class.by_score_type([ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT])

      expect(result).to include(classrooms_grade)
    end

    it 'excludes the grade when the differentiated exam rule matches but no enrolled student uses it' do
      classrooms_grade = create(:classrooms_grade, exam_rule: numeric_exam_rule_with_differentiated)
      enroll_student(classrooms_grade, uses_differentiated_exam_rule: false)

      result = described_class.by_score_type([ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT])

      expect(result).to_not include(classrooms_grade)
    end
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:grade) }
    it { expect(subject).to belong_to(:exam_rule) }
    it { expect(subject).to have_many(:student_enrollment_classrooms) }
    it { expect(subject).to have_one(:lessons_board) }
  end
end

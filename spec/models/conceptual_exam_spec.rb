require 'rails_helper'

RSpec.describe ConceptualExam, type: :model do
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }

  subject do
    build(
      :conceptual_exam,
      classroom: classroom,
      step_id: classroom.calendar.classroom_steps.first.id
    )
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to have_many(:conceptual_exam_values) }
  end

  describe 'validations' do
    # it { expect(subject).to validate_presence_of(:classroom) } -- verificar como resolver
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:recorded_at) }
    it { expect(subject).to validate_not_in_future_of(:recorded_at) }
    # it { expect(subject).to validate_school_term_day_of(:recorded_at) } -- Verificar outra forma de fazer

    it 'should require student to have conceptual exam score type' do
      invalid_score_types = [ ScoreTypes::DONT_USE, ScoreTypes::NUMERIC ]
      expected_message = I18n.t(
        '.activerecord.errors.models.conceptual_exam.attributes.student' \
        '.classroom_must_have_conceptual_exam_score_type'
      )

      invalid_score_types.each do |invalid_score_type|
        subject.classroom.exam_rule.score_type = invalid_score_type
        subject.student.uses_differentiated_exam_rule = false

        subject.valid?

        expect(subject.errors[:student]).to include(expected_message)
      end
    end
  end

  describe '#merge_conceptual_exam_values' do
    it 'overrides the new value over the persisted one' do
      subject.save!(validate: false)
      conceptual_exam_value = create(:conceptual_exam_value, value: 100, conceptual_exam: subject)
      expect(subject.conceptual_exam_values.first.value).to eq 100

      attributes = {
        conceptual_exam_values_attributes: {
          '1' => {
            discipline_id: conceptual_exam_value.discipline_id,
            value: 200
          },
          '2' => {
            discipline_id: Discipline.first.id,
            value: 300
          }
        }
      }
      subject.assign_attributes(attributes)

      subject.merge_conceptual_exam_values

      expect(subject.conceptual_exam_values.size).to eq 2
      expect(subject.conceptual_exam_values.first.value).to eq 200
      expect(subject.conceptual_exam_values.last.value).to eq 300
    end

    it 'maintains only the persited if do not have new values' do
      subject.save!(validate: false)
      create(:conceptual_exam_value, value: 100, conceptual_exam: subject)
      expect(subject.conceptual_exam_values.first.value).to eq 100

      subject.merge_conceptual_exam_values

      expect(subject.conceptual_exam_values.size).to eq 1
      expect(subject.conceptual_exam_values.first.value).to eq 100
    end
  end
end

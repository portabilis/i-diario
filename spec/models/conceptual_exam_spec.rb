require 'rails_helper'

RSpec.describe ConceptualExam, type: :model do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, :current, unity: unity) }
  let(:school_calendar) { create(:current_school_calendar_with_one_step, unity: unity) }

  subject do
    build(
      :conceptual_exam,
      classroom: classroom,
      step_id: school_calendar.steps.first.id
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
end

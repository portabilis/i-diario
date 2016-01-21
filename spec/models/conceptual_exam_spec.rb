require 'rails_helper'

RSpec.describe ConceptualExam, type: :model do
  subject { build(:conceptual_exam) }

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:school_calendar_step) }
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to have_many(:conceptual_exam_values) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:school_calendar_step) }
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:recorded_at) }
    it { expect(subject).to validate_not_in_future_of(:recorded_at) }
    it { expect(subject).to validate_school_term_day_of(:recorded_at) }

    it 'should require classroom to have conceptual exam score type' do
      invalid_score_types = [ ScoreTypes::DONT_USE, ScoreTypes::NUMERIC ]
      expected_message = I18n.t(
        '.activerecord.errors.models.conceptual_exam.attributes.classroom' \
        '.classroom_must_have_conceptual_exam_score_type'
      )

      invalid_score_types.each do |invalid_score_type|
        subject.classroom.exam_rule.score_type = invalid_score_type

        subject.valid?

        expect(subject.errors[:classroom]).to include(expected_message)
      end
    end
  end
end

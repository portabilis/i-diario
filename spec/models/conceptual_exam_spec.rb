require 'rails_helper'

RSpec.describe ConceptualExam, type: :model do
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
  end
end

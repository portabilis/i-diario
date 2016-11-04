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
end

require 'rails_helper'

RSpec.describe IepPeriodicEvaluation, type: :model do
  describe 'discipline XOR knowledge area (exactly one)' do
    it 'is valid with only a discipline' do
      evaluation = build(:iep_periodic_evaluation)

      expect(evaluation).to be_valid
    end

    it 'is valid with only a knowledge area' do
      evaluation = build(:iep_periodic_evaluation, :by_knowledge_area)

      expect(evaluation).to be_valid
    end

    it 'is invalid without a discipline and without a knowledge area' do
      evaluation = build(:iep_periodic_evaluation, discipline: nil, knowledge_area: nil)

      expect(evaluation).not_to be_valid
      expect(evaluation.errors[:base]).to include(
        I18n.t('activerecord.errors.messages.component_or_experience_required')
      )
    end

    it 'is invalid with both a discipline and a knowledge area' do
      evaluation = build(:iep_periodic_evaluation, :by_knowledge_area, discipline: create(:discipline))

      expect(evaluation).not_to be_valid
    end
  end
end

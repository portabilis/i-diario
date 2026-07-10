require 'rails_helper'

RSpec.describe IepCurricularPlanning, type: :model do
  describe 'discipline XOR knowledge area (exactly one)' do
    it 'is valid with only a discipline' do
      planning = build(:iep_curricular_planning)

      expect(planning).to be_valid
    end

    it 'is valid with only a knowledge area' do
      planning = build(:iep_curricular_planning, :by_knowledge_area)

      expect(planning).to be_valid
    end

    it 'is invalid without a discipline and without a knowledge area' do
      planning = build(:iep_curricular_planning, discipline: nil, knowledge_area: nil)

      expect(planning).not_to be_valid
      expect(planning.errors[:base]).to include(
        I18n.t('activerecord.errors.messages.component_or_experience_required')
      )
    end

    it 'is invalid with both a discipline and a knowledge area' do
      planning = build(:iep_curricular_planning, :by_knowledge_area, discipline: create(:discipline))

      expect(planning).not_to be_valid
      expect(planning.errors[:base]).to include(
        I18n.t('activerecord.errors.messages.component_or_experience_required')
      )
    end
  end
end

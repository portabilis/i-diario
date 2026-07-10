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

  describe 'accommodation multi-select by kind' do
    let(:planning) { create(:iep_curricular_planning) }
    let!(:instructional_a) { create(:iep_option, :instructional_accommodation) }
    let!(:instructional_b) { create(:iep_option, :instructional_accommodation) }
    let!(:environmental) { create(:iep_option, kind: IepOptionKinds::ENVIRONMENTAL_ACCOMMODATION) }

    it 'persists only ids of the given kind and ignores ids from other kinds' do
      planning.instructional_accommodation_option_ids =
        [instructional_a.id, instructional_b.id, environmental.id]
      planning.save!

      expect(planning.reload.instructional_accommodation_option_ids)
        .to match_array([instructional_a.id, instructional_b.id])
    end

    it 'does not affect options of another kind when updating a kind' do
      planning.environmental_accommodation_option_ids = [environmental.id]
      planning.instructional_accommodation_option_ids = [instructional_a.id]
      planning.save!

      planning.instructional_accommodation_option_ids = []
      planning.save!

      expect(planning.reload.environmental_accommodation_option_ids).to match_array([environmental.id])
    end
  end
end

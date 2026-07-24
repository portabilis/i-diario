require 'rails_helper'

RSpec.describe IepCurricularPlanning, type: :model do
  it { expect(subject).to belong_to(:iep_review_date) }
  it { expect(subject).to validate_presence_of(:iep_review_date_id) }

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

  describe 'review date must belong to the same plan' do
    it 'is invalid when the review date is from another plan' do
      plan_a = create(:individualized_educational_plan)
      plan_b = create(:individualized_educational_plan)
      review_from_b = create(:iep_review_date, iep: plan_b)

      planning = build(:iep_curricular_planning, iep: plan_a, iep_review_date: review_from_b)

      expect(planning).not_to be_valid
      expect(planning.errors[:iep_review_date_id]).to include(I18n.t('errors.messages.invalid'))
    end

    it 'is valid when the review date belongs to the same plan' do
      plan = create(:individualized_educational_plan)
      review = create(:iep_review_date, iep: plan)

      planning = build(:iep_curricular_planning, iep: plan, iep_review_date: review)

      expect(planning).to be_valid
    end
  end

  describe 'unique component per review' do
    it 'is invalid to add the same discipline twice in the same review' do
      plan = create(:individualized_educational_plan)
      review = create(:iep_review_date, iep: plan)
      discipline = create(:discipline)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review, discipline: discipline)

      duplicate = build(:iep_curricular_planning, iep: plan, iep_review_date: review, discipline: discipline)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:discipline_id]).to be_present
    end

    it 'allows the same discipline in different reviews of the same plan' do
      plan = create(:individualized_educational_plan)
      review_a = create(:iep_review_date, iep: plan)
      review_b = create(:iep_review_date, iep: plan)
      discipline = create(:discipline)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review_a, discipline: discipline)

      other = build(:iep_curricular_planning, iep: plan, iep_review_date: review_b, discipline: discipline)

      expect(other).to be_valid
    end
  end

  describe '#empty_content?' do
    it 'is true when all text fields and accommodations are blank' do
      planning = build(:iep_curricular_planning, long_term_goal: '', stage_objectives: '',
                                                 skills_to_develop: '', methodologies: '')

      expect(planning.empty_content?).to eq(true)
    end

    it 'is false when a text field is filled' do
      planning = build(:iep_curricular_planning, long_term_goal: 'Meta')

      expect(planning.empty_content?).to eq(false)
    end

    it 'is false when only accommodations are selected (no text)' do
      planning = create(:iep_curricular_planning)
      planning.instructional_accommodation_option_ids =
        [create(:iep_option, :instructional_accommodation).id]

      expect(planning.empty_content?).to eq(false)
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

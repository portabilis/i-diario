require 'rails_helper'

RSpec.describe IepReviewDate, type: :model do
  it { expect(subject).to belong_to(:iep).class_name('IndividualizedEducationalPlan') }
  it { expect(subject).to have_many(:iep_curricular_plannings) }
  it { expect(subject).to have_many(:iep_periodic_evaluations) }
  it { expect(subject).to validate_presence_of(:review_date) }

  describe '#destroy' do
    let(:review_date) { create(:iep_review_date) }

    it 'is blocked when the review has curricular planning data (section 4)' do
      create(:iep_curricular_planning, iep: review_date.iep, iep_review_date: review_date)

      expect(review_date.destroy).to eq(false)
      expect(review_date.errors[:base]).to include(
        'Não é possível remover a revisão prevista, pois já existem informações preenchidas para o período'
      )
    end

    it 'is blocked when the review has periodic evaluation data (section 5)' do
      create(:iep_periodic_evaluation, iep: review_date.iep, iep_review_date: review_date)

      expect(review_date.destroy).to eq(false)
      expect(review_date.errors[:base]).to include(
        'Não é possível remover a revisão prevista, pois já existem informações preenchidas para o período'
      )
    end

    it 'is allowed when the review has no data in sections 4/5' do
      review_date

      expect { review_date.destroy }.to change(described_class, :count).by(-1)
    end

    it 'is allowed when destroyed as part of the parent plan cascade (destroyed_by_association)' do
      create(:iep_curricular_planning, iep: review_date.iep, iep_review_date: review_date)

      # Recarrega o plano do banco (como o controller faz): `review_date.iep` traria a
      # associação iep_review_dates cacheada da criação, antes de a revisão existir.
      plan = IndividualizedEducationalPlan.find(review_date.iep.id)

      expect { plan.destroy }.to change(described_class, :count).by(-1)
    end
  end
end

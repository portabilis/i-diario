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
        I18n.t('activerecord.errors.models.iep_review_date.in_use')
      )
    end

    it 'is blocked when the review has periodic evaluation data (section 5)' do
      create(:iep_periodic_evaluation, iep: review_date.iep, iep_review_date: review_date)

      expect(review_date.destroy).to eq(false)
      expect(review_date.errors[:base]).to include(
        I18n.t('activerecord.errors.models.iep_review_date.in_use')
      )
    end

    it 'is allowed when the review has no data in sections 4/5' do
      review_date

      expect { review_date.destroy }.to change(described_class, :count).by(-1)
    end
  end
end

require 'rails_helper'

RSpec.describe IepReviewDate, type: :model do
  it { expect(subject).to belong_to(:iep).class_name('IndividualizedEducationalPlan') }
  it { expect(subject).to validate_presence_of(:review_date) }
end

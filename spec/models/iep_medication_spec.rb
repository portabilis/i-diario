require 'rails_helper'

RSpec.describe IepMedication, type: :model do
  it { expect(subject).to belong_to(:iep).class_name('IndividualizedEducationalPlan') }
  it { expect(subject).to validate_presence_of(:name) }
end

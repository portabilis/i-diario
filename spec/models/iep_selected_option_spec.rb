require 'rails_helper'

RSpec.describe IepSelectedOption, type: :model do
  it { expect(subject).to belong_to(:iep).class_name('IndividualizedEducationalPlan') }
  it { expect(subject).to belong_to(:iep_option) }
  it { expect(subject).to validate_presence_of(:iep_option_id) }
end

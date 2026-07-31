require 'rails_helper'

RSpec.describe IepCurricularPlanningOption, type: :model do
  it { expect(subject).to belong_to(:iep_curricular_planning) }
  it { expect(subject).to belong_to(:iep_option) }
  it { expect(subject).to validate_presence_of(:iep_option_id) }
end

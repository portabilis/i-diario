require 'rails_helper'

RSpec.describe IepSelectedOption, type: :model do
  it { expect(subject).to belong_to(:iep).class_name('IndividualizedEducationalPlan') }
  it { expect(subject).to belong_to(:iep_option) }
  it { expect(subject).to validate_presence_of(:iep_option_id) }

  describe 'audit trail' do
    it 'records the plan as the associated audit (associated_with: :iep)' do
      plan = create(:individualized_educational_plan)
      option = create(:iep_selected_option, iep: plan)

      audit = option.audits.last
      expect(audit.associated_type).to eq('IndividualizedEducationalPlan')
      expect(audit.associated_id).to eq(plan.id)
    end
  end
end

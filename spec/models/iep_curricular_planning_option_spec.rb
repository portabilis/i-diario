require 'rails_helper'

RSpec.describe IepCurricularPlanningOption, type: :model do
  it { expect(subject).to belong_to(:iep_curricular_planning) }
  it { expect(subject).to belong_to(:iep_option) }
  it { expect(subject).to validate_presence_of(:iep_option_id) }

  describe 'audit trail' do
    it 'records the curricular planning line as the associated audit (associated_with: :iep_curricular_planning)' do
      planning = create(:iep_curricular_planning)
      option = create(:iep_curricular_planning_option, iep_curricular_planning: planning)

      audit = option.audits.last
      expect(audit.associated_type).to eq('IepCurricularPlanning')
      expect(audit.associated_id).to eq(planning.id)
    end
  end
end

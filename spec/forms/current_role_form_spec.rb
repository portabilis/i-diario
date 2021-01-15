require 'rails_helper'

RSpec.describe CurrentRoleForm, type: :model do
  describe 'validations' do
    it { expect(subject).to validate_presence_of(:current_user) }
  end
end

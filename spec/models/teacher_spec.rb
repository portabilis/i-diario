require 'rails_helper'

RSpec.describe Teacher, :type => :model do
  context "Validations" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :api_code }

    it { expect(subject).to allow_value(true).for :active }
    it { expect(subject).to allow_value(false).for :active }
    it { expect(subject).to_not allow_value(nil).for :active }
  end
end

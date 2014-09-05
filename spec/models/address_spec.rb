require 'rails_helper'

RSpec.describe Address, :type => :model do
  context "Validations" do
    it { should allow_value("32672-124").for(:zip_code) }
    it { should_not allow_value("32672124").for(:zip_code) }
    it { should_not allow_value("3267-124").for(:zip_code) }
  end
end

require 'rails_helper'

RSpec.describe Entity, :type => :model do
  context "Validations" do
    it { expect(subject).to validate_presence_of(:name) }
    it { expect(subject).to validate_presence_of(:domain) }
    it { expect(subject).to validate_presence_of(:config) }
  end
end

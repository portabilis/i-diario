require 'rails_helper'

RSpec.describe Teacher, :type => :model do
  context "Validations" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :api_code }

    it '' do
      subject.name = "Valdite Santos"
      subject.api_code = "245145"
      subject.active = false

      expect(subject.valid?).to be(true)
    end
  end
end

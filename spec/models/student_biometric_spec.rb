require 'rails_helper'

RSpec.describe StudentBiometric, :type => :model do
  context "Validations" do
    it { should validate_presence_of :student_id }
    it { should validate_presence_of :biometric }
    it { should validate_presence_of :biometric_type }

    describe "uniqueness" do
      subject { StudentBiometric.new(student_id: FactoryGirl.create(:student).id, biometric_type: 1, biometric: "d12udh128dy1287dy12") }
      it { should validate_uniqueness_of(:biometric_type).scoped_to(:student_id) }
    end
  end
end

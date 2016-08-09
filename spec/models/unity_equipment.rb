# encoding: utf-8
require 'rails_helper'

RSpec.describe UnityEquipment, :type => :model do
  context "associations" do
    it { should belong_to :unity }
  end

  context "Validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :code }
    it { should validate_presence_of :biometric_type }

    describe "uniqueness" do
      subject { UnityEquipment.new(unity: FactoryGirl.create(:unity), biometric_type: 1, code: 1) }
      it { should validate_uniqueness_of(:code).scoped_to(:unity_id) }
    end
  end
end

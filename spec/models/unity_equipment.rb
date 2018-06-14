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

    it 'saves when there is only one record' do
      unity_equipment = build(:unity_equipment)

      expect(unity_equipment.save).to be_truthy
    end

    it 'accepts non numeric characters on code' do
      unity_equipment = build(:unity_equipment)
      unity_equipment.code = 'PQR-45'

      expect(unity_equipment.save).to be_truthy
    end

    describe "uniqueness" do
      subject { create(:unity_equipment) }

      it { should validate_uniqueness_of(:code).case_insensitive.scoped_to(:unity_id) }
    end
  end
end

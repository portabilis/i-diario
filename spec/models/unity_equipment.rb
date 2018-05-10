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

    it 'should save when there is only one record' do
      unity = FactoryGirl.create(:unity)
      unity_equipment = UnityEquipment.new(
        unity: unity,
        biometric_type: BiometricTypes::SAGEM,
        code: '001'
      )
      expect(unity_equipment.save).to eq true
    end

    it 'should accept non numeric characters on code' do
      unity = FactoryGirl.create(:unity)
      unity_equipment = UnityEquipment.new(
        unity: unity,
        biometric_type: BiometricTypes::SAGEM,
        code: 'PQR-45'
      )
      expect(unity_equipment.save).to eq true
    end

    it 'should validate uniquiness of code and unity' do
      unity = FactoryGirl.create(:unity)
      unity_equipment = UnityEquipment.new(
        unity: unity,
        biometric_type: BiometricTypes::SAGEM,
        code: '001'
      )
      unity_equipment.save!

      same_unity_equipment = UnityEquipment.new(
        unity: unity,
        biometric_type: BiometricTypes::SAGEM,
        code: '001'
      )
      expect(same_unity_equipment.valid?).to eq false

      different_unity_equipment = UnityEquipment.new(
        unity: unity,
        biometric_type: BiometricTypes::SAGEM,
        code: '002'
      )
      expect(different_unity_equipment.valid?).to eq true

      other_unity = FactoryGirl.create(:unity)
      other_unity_equipment = UnityEquipment.new(
        unity: other_unity,
        biometric_type: BiometricTypes::SAGEM,
        code: '001'
      )
      expect(other_unity_equipment.valid?).to eq true
    end
  end
end

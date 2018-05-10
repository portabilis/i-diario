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
      unity = FactoryGirl.create(:unity)
      unity_equipment = FactoryGirl.create(:unity_equipment)
      unity_equipment.unity = unity

      expect(unity_equipment.save).to eq true
    end

    it 'accepts non numeric characters on code' do
      unity = FactoryGirl.create(:unity)
      unity_equipment = FactoryGirl.create(:unity_equipment)
      unity_equipment.unity = unity
      unity_equipment.code = 'PQR-45'

      expect(unity_equipment.save).to eq true
    end

    it 'validates uniquiness of code and unity' do
      unity = FactoryGirl.create(:unity)
      unity_equipment = FactoryGirl.create(:unity_equipment)
      unity_equipment.unity = unity
      unity_equipment.save!

      same_unity_equipment = FactoryGirl.create(:unity_equipment)
      same_unity_equipment.unity = unity
      same_unity_equipment.code = unity_equipment.code
      same_unity_equipment.valid?

      expect(same_unity_equipment.errors[:code]).to include('já está em uso')

      different_unity_equipment = FactoryGirl.create(:unity_equipment)
      different_unity_equipment.unity = unity
      different_unity_equipment.valid?

      expect(different_unity_equipment.errors[:code]).to be_empty

      other_unity = FactoryGirl.create(:unity)
      other_unity_equipment = FactoryGirl.create(:unity_equipment)
      other_unity_equipment.unity = other_unity
      other_unity_equipment.code = unity_equipment.code
      other_unity_equipment.valid?

      expect(different_unity_equipment.errors[:code]).to be_empty
    end
  end
end

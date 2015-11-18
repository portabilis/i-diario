require 'rails_helper'

RSpec.describe ***REMOVED***, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:food) }
    it { expect(subject).to belong_to(:material) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:material_id) }
    
    describe "validates material classification" do
      context "when material classification is permanent" do
        material = FactoryGirl.create(:material, classification: ***REMOVED***Classifications::PERMANENT)
        subject = FactoryGirl.build(:food_material, material: material)

        it { expect(subject.valid?).to be(false) }
        it { expect(subject.errors[:material_id]).to include('deve ser um material de consumo') }
      end

      context "when material classification is consumption" do
        material = FactoryGirl.create(:material, classification: ***REMOVED***Classifications::CONSUMPTION)
        subject = FactoryGirl.build(:food_material, material: material)

        it { expect(subject.valid?).to be(true) }
      end
    end
  end
end

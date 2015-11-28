require 'rails_helper'

RSpec.describe ***REMOVED***Menu, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to :food }
    it { expect(subject).to belong_to :***REMOVED*** }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:food_id) }

    context "when food has not ***REMOVED***" do
      it "expects to not be valid" do
        ***REMOVED*** = FactoryGirl.build(:***REMOVED***)
        food_with_no_***REMOVED*** = FactoryGirl.create(:food)
        subject = FactoryGirl.build(:food_***REMOVED***, ***REMOVED***: ***REMOVED***, food: food_with_no_***REMOVED***)

        expect(subject.valid?).to be(false)
        expect(subject.errors[:food_id]).to include('deve possuir materiais')
      end
    end
  end
end

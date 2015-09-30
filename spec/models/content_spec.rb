require 'rails_helper'

RSpec.describe Content, :type => :model do
  subject { FactoryGirl.build(:content) }

  describe "associations" do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:content_date) }
    it { expect(subject).to validate_presence_of(:theme) }
  end
end

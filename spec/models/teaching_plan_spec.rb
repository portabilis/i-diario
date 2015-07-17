require 'rails_helper'

RSpec.describe TeachingPlan, type: :model do
  describe "attributes" do
    it { expect(subject).to respond_to(:classroom) }
    it { expect(subject).to respond_to(:discipline) }
    it { expect(subject).to respond_to(:school_calendar_step) }
    it { expect(subject).to respond_to(:objectives) }
    it { expect(subject).to respond_to(:content) }
    it { expect(subject).to respond_to(:methodology) }
    it { expect(subject).to respond_to(:evaluation) }
    it { expect(subject).to respond_to(:references) }
  end

  describe "associations" do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar_step) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:school_calendar_step) }
  end
end

require 'rails_helper'

RSpec.describe Content, :type => :model do
  describe "associations" do
    it { should belong_to :unity }
    it { should belong_to :classroom }
    it { should belong_to :discipline }
    it { should belong_to :school_calendar }
    it { should belong_to :knowledge_area }
  end

  describe "validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :classroom }
    it { should validate_presence_of :school_calendar }
    it { should validate_presence_of :content_date }
    it { should validate_presence_of :classes }
    it { should validate_presence_of :description }
  end
end

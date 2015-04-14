require 'rails_helper'

RSpec.describe TestSettingTest, :type => :model do
  describe "associations" do
    it { should belong_to :test_setting }
  end

  describe "validations" do
    it { should validate_presence_of :description }
    it { should validate_presence_of :weight }
    it { should validate_presence_of :test_type }
    it { should validate_numericality_of :weight }
  end
end

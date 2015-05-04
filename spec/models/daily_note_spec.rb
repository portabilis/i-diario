# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNote, :type => :model do
  describe "associations" do
    it { should belong_to :unity }
    it { should belong_to :classroom }
    it { should belong_to :discipline }
    it { should belong_to :avaliation }
    it { should have_many :students }
  end

  describe "validations" do
    it { should validate_presence_of :unity }
    it { should validate_presence_of :classroom }
    it { should validate_presence_of :discipline }
    it { should validate_presence_of :avaliation }
  end
end

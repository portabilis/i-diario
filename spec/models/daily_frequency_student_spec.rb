# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyFrequencyStudent, :type => :model do
  describe "associations" do
    it { should belong_to :daily_frequency }
    it { should belong_to :student }
  end

  describe "validations" do
    it { should validate_presence_of :student }
    it { should validate_presence_of :daily_frequency }
  end
end

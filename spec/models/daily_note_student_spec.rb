# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNoteStudent, :type => :model do
  describe "associations" do
    it { should belong_to :daily_note }
    it { should belong_to :student }
  end

  describe "validations" do
    it { should validate_presence_of :student }
    it { should validate_presence_of :daily_note }

    context "if note is present" do
      before { subject.note = 3 }

      it { should validate_numericality_of :note }
    end
  end
end

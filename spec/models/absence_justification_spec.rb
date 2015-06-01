require 'rails_helper'

RSpec.describe AbsenceJustification, :type => :model do

  describe "associations" do
    it { should belong_to :student }
  end

  describe "validations" do

    it { should validate_presence_of :student }
    it { should validate_presence_of :absence_date }
    it { should validate_presence_of :justification }

    context "given that I have a record persisted" do
      fixtures :students, :absence_justifications

      it { should validate_uniqueness_of(:absence_date).scoped_to(:student_id) }
    end
  end
end

require 'rails_helper'

RSpec.describe AbsenceJustification, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:author) }
    it { expect(subject).to belong_to(:student) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:author) }
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:absence_date) }
    it { expect(subject).to validate_presence_of(:absence_date_end) }
    it { expect(subject).to validate_presence_of(:justification) }

    context "given that I have a record persisted" do
      fixtures :students, :absence_justifications

      it { expect(subject).to validate_uniqueness_of(:absence_date).scoped_to(:student_id) }
      it { expect(subject).to validate_uniqueness_of(:absence_date_end).scoped_to(:student_id) }
    end
  end
end

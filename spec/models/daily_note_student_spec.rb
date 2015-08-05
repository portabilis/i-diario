# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNoteStudent, type: :model do
  let(:discipline) { create(:discipline) }
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:school_calendar) { create(:school_calendar, year: 2020) }
  let(:avaliation) { create(:avaliation, unity: unity, classroom: classroom, discipline: discipline, school_calendar: school_calendar) }
  let(:daily_note) { create(:daily_note, unity: unity, classroom: classroom, discipline: discipline, avaliation: avaliation) }
  subject(:daily_note_student) { build(:daily_note_student, daily_note: daily_note) }

  describe "attributes" do
    describe "note" do
      context "when receive a localized value" do
        before { subject.note = "1.500,25" }

        it "delocates the value" do
          expect(subject.note).to eq(1500.25)
        end
      end
    end
  end

  describe "associations" do
    it { expect(subject).to belong_to(:daily_note) }
    it { expect(subject).to belong_to(:student) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:daily_note) }
    it { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                           .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting.maximum_score) }
    it { expect(subject).to allow_value('', nil).for(:note) }
  end
end
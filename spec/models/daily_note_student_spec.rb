# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNoteStudent, type: :model do
  let(:discipline) { create(:discipline) }
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:avaliation) { create(:avaliation, unity: unity, classroom: classroom, discipline: discipline) }
  let(:daily_note) { create(:daily_note, unity: unity, classroom: classroom, discipline: discipline, avaliation: avaliation) }
  subject(:daily_note_student) { build(:daily_note_student, daily_note: daily_note) }

  describe "associations" do
    it { expect(subject).to belong_to(:daily_note) }
    it { expect(subject).to belong_to(:student) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:daily_note) }
    it { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                           .is_less_than_or_equal_to(subject.daily_note.avaliation.school_calendar.maximum_score) }
    it { expect(subject).to allow_value('', nil).for(:note) }
  end
end
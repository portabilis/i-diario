require 'rails_helper'

RSpec.describe DailyNoteStudent, type: :model do
  let(:discipline) { create(:discipline) }
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2014) }
  let(:avaliation) { create(:avaliation, unity: unity, classroom: classroom, discipline: discipline, school_calendar: school_calendar, test_date: '2014-02-06') }
  let(:daily_note) { create(:daily_note, unity: unity, classroom: classroom, discipline: discipline, avaliation: avaliation) }
  subject(:daily_note_student) { build(:daily_note_student, daily_note: daily_note) }

  describe 'associations' do
    it { expect(subject).to belong_to(:daily_note) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:daily_note) }

    context 'when test_setting with no fixed tests' do
      let(:test_setting) { create(:test_setting, fix_tests: false) }
      let(:avaliation) { create(:avaliation, unity: unity, classroom: classroom, discipline: discipline, school_calendar: school_calendar, test_setting: test_setting, test_date: '2014-02-06') }
      let(:daily_note) { create(:daily_note, unity: unity, classroom: classroom, discipline: discipline, avaliation: avaliation) }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting.maximum_score)
                                                             .allow_nil }
    end

    context 'when test_setting with fixed tests and that do not allow break up' do
      let(:test_setting_with_fixed_tests_that_do_not_allow_break_up) { FactoryGirl.create(:test_setting_with_fixed_tests) }
      let(:avaliation) { create(:avaliation, unity: unity,
                                             classroom: classroom,
                                             discipline: discipline,
                                             school_calendar: school_calendar,
                                             test_setting: test_setting_with_fixed_tests_that_do_not_allow_break_up,
                                             test_setting_test: test_setting_with_fixed_tests_that_do_not_allow_break_up.tests.first,
                                             weight: nil,
                                             test_date: '2014-02-06') }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting_test.weight)
                                                             .allow_nil }
    end

    context 'when test_setting with fixed tests and that allow break up' do
      let(:test_setting_with_fixed_tests_that_allow_break_up) { FactoryGirl.create(:test_setting_with_fixed_tests_that_allow_break_up) }
      let(:avaliation) { create(:avaliation, unity: unity,
                                             classroom: classroom,
                                             discipline: discipline,
                                             school_calendar: school_calendar,
                                             test_setting: test_setting_with_fixed_tests_that_allow_break_up,
                                             test_setting_test: test_setting_with_fixed_tests_that_allow_break_up.tests.first,
                                             weight: test_setting_with_fixed_tests_that_allow_break_up.tests.first.weight / 2,
                                             test_date: '2014-02-06') }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.weight)
                                                             .allow_nil }
    end
  end
end

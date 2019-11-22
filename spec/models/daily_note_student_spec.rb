require 'rails_helper'

RSpec.describe DailyNoteStudent, type: :model do
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      discipline: discipline,
      teacher: teacher
    )
  }
  let(:avaliation) {
    create(
      :avaliation,
      classroom: classroom,
      discipline: discipline,
      teacher: teacher,
      teacher_id: teacher.id
    )
  }
  let(:daily_note) { create(:daily_note, avaliation: avaliation) }
  subject(:daily_note_student) { build(:daily_note_student, daily_note: daily_note) }

  describe 'associations' do
    it { expect(subject).to belong_to(:daily_note) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:student) }
    it { expect(subject).to validate_presence_of(:daily_note) }

    context 'when test_setting with arithmetic calculation type tests' do
      let(:test_setting) { create(:test_setting, average_calculation_type: AverageCalculationTypes::ARITHMETIC) }
      let(:avaliation) {
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          test_setting: test_setting,
          teacher: teacher,
          teacher_id: teacher.id
        )
      }
      let(:daily_note) { create(:daily_note, avaliation: avaliation) }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it {
        expect(subject).to validate_numericality_of(:note)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting.maximum_score)
          .allow_nil
      }
    end

    context 'when test_setting with sum calculation type and that do not allow break up' do
      let(:test_setting_with_sum_calculation_type) { create(:test_setting_with_sum_calculation_type) }
      let(:avaliation) {
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          test_setting: test_setting_with_sum_calculation_type,
          test_setting_test: test_setting_with_sum_calculation_type.tests.first,
          weight: nil,
          teacher: teacher,
          teacher_id: teacher.id
        )
      }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it {
        expect(subject).to validate_numericality_of(:note)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting_test.weight)
          .allow_nil
      }
    end

    context 'when test_setting with sum calculation type and that allow break up' do
      let(:test_setting_with_sum_calculation_type_that_allow_break_up) {
        create(:test_setting_with_sum_calculation_type_that_allow_break_up)
      }
      let(:avaliation) {
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          test_setting: test_setting_with_sum_calculation_type_that_allow_break_up,
          test_setting_test: test_setting_with_sum_calculation_type_that_allow_break_up.tests.first,
          weight: test_setting_with_sum_calculation_type_that_allow_break_up.tests.first.weight / 2,
          teacher: teacher,
          teacher_id: teacher.id
        )
      }
      subject { build(:daily_note_student, daily_note: daily_note) }

      it {
        expect(subject).to validate_numericality_of(:note)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(subject.daily_note.avaliation.weight)
          .allow_nil
      }
    end
  end
end

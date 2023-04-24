require 'rails_helper'

RSpec.describe TestSettingFetcher, type: :service do
  let!(:classroom) { create(:classroom, :with_classroom_trimester_steps, year: 2019) }
  let!(:step) { classroom.calendar.classroom_steps.first }
  let!(:school_term_type) { create(:school_term_type, steps_number: 3) }
  let!(:school_term_type_step) { create(:school_term_type_step, school_term_type: school_term_type) }

  context 'when does not receive classroom' do
    it 'raises ArgumentError to classroom' do
      expect { described_class.new(nil, 1).current(nil) }.to raise_error(ArgumentError)
    end
  end

  context 'test setting type is general' do
    let!(:general_test_setting) {
      create(
        :test_setting,
        exam_setting_type: ExamSettingTypes::GENERAL,
        year: classroom.year
      )
    }

    context 'test setting exist for step year' do
      it 'returns current test setting as general' do
        expect(described_class.current(classroom)).to eq(general_test_setting)
      end
    end

    context 'test setting doesnt exist for step year' do
      before do
        general_test_setting.update(year: general_test_setting.year + 1)
      end

      it 'returns nil to current test setting as general' do
        expect(described_class.current(classroom)).to eq(nil)
      end
    end
  end

  context 'test setting type is school_term' do
    let!(:step_test_setting) {
      create(
        :test_setting,
        exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM,
        school_term_type_step: school_term_type_step,
        year: classroom.year
      )
    }

    context 'test setting exists for step year and school_term' do
      it 'returns current test setting of step' do
        allow(step.school_calendar).to receive(:year).and_return(2019)
        expect(described_class.current(classroom, step)).to eq(step_test_setting)
      end
    end

    context 'test setting doesnt exist for step year and school_term' do
      before do
        step_test_setting.update(
          school_term_type_step: school_term_type_step
        )
      end

      it 'returns nil to current test setting of step' do
        expect(described_class.current(classroom)).to eq(nil)
      end
    end
  end
end

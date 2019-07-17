require 'rails_helper'

RSpec.describe TestSettingFetcher, type: :service do
  let!(:classroom) { create(:classroom, :current) }
  let!(:school_calendar) {
    create(
      :school_calendar,
      :school_calendar_with_trimester_steps,
      unity: classroom.unity,
      year: classroom.year
    )
  }

  context 'test setting type is general' do
    let!(:general_test_setting) {
      create(
        :test_setting,
        exam_setting_type: ExamSettingTypes::GENERAL,
        year: classroom.year
      )
    }

    context 'test setting exist for step year' do
      it 'return test setting of year of step' do
        expect(described_class.by_step(school_calendar.steps.first)).to eq(general_test_setting)
      end

      it 'return current test setting as general' do
        expect(described_class.current(classroom)).to eq(general_test_setting)
      end
    end

    context 'test setting doesnt exist for step year' do
      before do
        general_test_setting.update(year: general_test_setting.year + 1)
      end

      it 'return nil' do
        expect(described_class.by_step(school_calendar.steps.first)).to be(nil)
      end

      it 'return nil to current test setting as general' do
        expect(described_class.current(classroom)).to eq(nil)
      end
    end
  end

  context 'test setting type is school_term' do
    let!(:step_test_setting) {
      create(
        :test_setting,
        exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM,
        school_term: SchoolTerms::FIRST_TRIMESTER,
        year: classroom.year
      )
    }

    context 'test setting exists for step year and school_term' do
      it 'return test setting of school term of step' do
        expect(described_class.by_step(school_calendar.steps.first)).to eq(step_test_setting)
      end

      it 'return current test setting of step' do
        expect(described_class.current(classroom)).to eq(step_test_setting)
      end
    end

    context 'test setting doesnt exist for step year and school_term' do
      before do
        step_test_setting.update(
          school_term: SchoolTerms::THIRD_TRIMESTER
        )
      end

      it 'return nil' do
        expect(described_class.by_step(school_calendar.steps.first)).to be(nil)
      end

      it 'return nil to current test setting of step' do
        expect(described_class.current(classroom)).to eq(nil)
      end
    end
  end
end

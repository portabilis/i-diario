require 'rails_helper'

RSpec.describe TestSettingFetcher, type: :service do
  let(:school_calendar) { create(:current_school_calendar_with_one_step) }
  let(:test_setting) { create(:test_setting, year: school_calendar.year) }

  context 'test setting type is general' do
    context 'test setting exist for step year' do
      before do
        test_setting.update_attribute(:exam_setting_type, ExamSettingTypes::GENERAL)
      end

      it 'return test setting of year of step' do
        expect(described_class.fetch(school_calendar.steps.first)).to eq(test_setting)
      end
    end

    context 'test setting doesnt exist for step year' do
      before do
        test_setting.update_attribute(:year, test_setting.year+1)
      end

      it 'return nil' do
        expect(described_class.fetch(school_calendar.steps.first)).to be(nil)
      end
    end
  end

  context 'test setting type is school_term' do
    context 'test setting exists for step year and school_term' do
      before do
        test_setting.update_attributes({
          exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM,
          school_term: school_calendar.steps.first.school_term
        })
      end

      it 'return test setting of school term of step' do
        expect(described_class.fetch(school_calendar.steps.first)).to eq(test_setting)
      end
    end

    context 'test setting doesnt exist for step year and school_term' do
      before do
        test_setting.update_attributes({
          exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM,
          school_term: 'third_trimester'
        })
      end

      it 'return nil' do
        expect(described_class.fetch(school_calendar.steps.first)).to be(nil)
      end
    end
  end
end
